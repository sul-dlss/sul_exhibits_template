# frozen_string_literal: true

##
# For a given object in an exhibit, gets the correct manifest, and enqueues
# canvas/page indexing jobs from that manifest.
class IiifCanvasIndexer
  attr_reader :exhibit, :druid

  ANNOTATION_LIST = 'sc:AnnotationList'

  delegate :manifest, to: :manifest_harvester

  def initialize(exhibit, druid)
    @exhibit = exhibit
    @druid = druid
  end

  def index_canvases
    canvases.each do |canvas|
      canvas.other_content.each do |other_content|
        # Don't bother to index unless there is an annotationList content to do so.
        next unless other_content['@type'] == ANNOTATION_LIST

        canvas_resource = CanvasResource.find_or_initialize_by(url: other_content['@id'], exhibit:)
        # We need to pass some more information to the canvas indexer, and we
        # so we do this by enhancing the stored Hash with needed fields.
        enhanced_canvas = JSON.parse(canvas.to_json)
        enhanced_canvas['manifest_label'] = manifest.label
        enhanced_canvas['parent_manuscript_number'] = document.fetch('manuscript_number_tesim', nil)
        enhanced_canvas['range_labels'] = range_labels_for(canvas['@id'])
        canvas_resource.data = enhanced_canvas
        canvas_resource.save_and_index
      end
    end
  end

  private

  def document
    ##
    # TODO: Often times the document is not yet commited. Not sure if we can
    # ensure this. At the moment, we just rely on job framework / retry.
    @document ||= SolrDocument.find(druid)
  end

  def manifest_url
    document.exhibit_specific_manifest(exhibit.required_viewer.custom_manifest_pattern)
  end

  def range_labels_for(canvas_id)
    @range_labels ||= {}
    @range_labels[canvas_id] ||= manifest_harvester.ranges_for(canvas_id).pluck('label')
  end

  def canvases
    return [] unless manifest_url

    @canvases ||= manifest_harvester.canvases
  end

  def manifest_harvester
    return unless manifest_url

    @manifest_harvester ||= IiifManifestHarvester.new(manifest_url)
  end
end
