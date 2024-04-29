# frozen_string_literal: true

require 'traject/adjust_cardinality'

# Base Resource harvester for objects in DOR
class DorHarvester < Spotlight::Resource
  store :data, accessors: [:druid_list, :collections]

  before_index :trigger_update_resource_metadata

  class << self
    def instance(current_exhibit)
      find_or_initialize_by exhibit: current_exhibit
    end
  end

  def self.indexing_pipeline
    @indexing_pipeline ||= super.dup.tap do |pipeline|
      pipeline.sources = [
        Spotlight::Etl::Sources::SourceMethodSource(:indexable_resources)
      ]

      pipeline.pre_processes += [
        lambda do |_data, p|
          next if p.source.exists?

          p.context.resource.on_error(p.source, 'Missing')

          throw(:skip)
        end
      ]

      pipeline.transforms = [
        lambda do |data, p|
          doc = p.context.resource.traject_indexer.map_record(p.source)

          throw(:skip) unless doc

          data.merge(Traject::AdjustCardinality.call(doc).symbolize_keys)
        end
      ] + pipeline.transforms

      pipeline.post_processes += [
        lambda do |_data, p|
          p.context.resource.on_success(p.source)
        end
      ]
    end
  end

  def traject_indexer
    @traject_indexer ||= Traject::Indexer.new.tap do |i|
      i.load_config_file('lib/traject/dor_config.rb')
    end
  end

  def resources
    return to_enum(:resources) { druids.size } unless block_given?

    druids.each { |d| yield Purl.new(d) }
  end

  def druids
    @druids ||= druid_list.split(/\s+/).reject(&:blank?).uniq
  end

  def collections
    data[:collections] ||= {}
    super
  end

  ##
  # Enumerate the resource, and any collection members, that should be indexed
  # into this exhibit
  #
  # @return [Enumerator] an enumerator of resources to index
  def indexable_resources
    return to_enum(:indexable_resources) { size } unless block_given?

    resources.each do |resource|
      yield resource

      next unless resource.exists?

      resource.items.each do |r|
        yield Purl.new(r.druid)
      end
    end
  end

  def on_success(resource)
    RecordIndexStatusJob.perform_later(self, resource.bare_druid, ok: true)
    IndexRelatedContentJob.perform_later(self, resource.bare_druid) if index_related_content?
  end

  def index_related_content?
    FeatureFlags.for(exhibit.slug).index_related_content?
  end

  def on_error(resource, exception_or_message)
    message = if exception_or_message.is_a? Exception
                exception_or_message.inspect
              else
                exception_or_message.to_s
              end.truncate(1.megabyte)
    RecordIndexStatusJob.perform_later(self, resource.bare_druid, ok: false, message:)
  end

  def trigger_update_resource_metadata
    update(collections: {})
    RecordResourceMetadataJob.perform_later(self)
  end

  def update_collection_metadata!
    update(collections: fetch_collection_metadata)
  end

  private

  def size
    @size ||= resources.select(&:exists?).sum { |r| r.collection? ? r.items.size : 1 }
  end

  def fetch_collection_metadata
    resources.select(&:exists?).select(&:collection?).each_with_object({}) do |obj, memo|
      memo[obj.bare_druid] = { size: obj.items.size }
    end
  end
end
