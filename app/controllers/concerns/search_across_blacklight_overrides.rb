# frozen_string_literal: true

##
# Concern to be mixed into SearchAcross controller that contains the Blacklight
# helper methods that need to be overridden only in the SearchAcross context.
module SearchAcrossBlacklightOverrides
  extend ActiveSupport::Concern

  included do
    if respond_to?(:helper_method)
      helper_method :link_to_document, :show_pagination?, :document_index_path_templates,
                    :render_grouped_document_index, :opensearch_catalog_url, :page_entries_info,
                    :render_grouped_response?, :url_for_document, :start_over_path
    end
  end

  def render_grouped_response?(*_args)
    params[:group]
  end

  # Disable Blacklight implicit links to documents
  def url_for_document(_doc)
    '#'
  end

  # Disable implicit links to documents
  def link_to_document(doc, field_or_opts, opts = { counter: nil })
    label = case field_or_opts
            when NilClass
              view_context.document_presenter(doc).heading
            when Hash
              opts = field_or_opts
              view_context.document_presenter(doc).heading
            when Proc, Symbol
              Deprecation.silence(Blacklight::IndexPresenter) do
                view_context.document_presenter(doc).label field_or_opts, opts
              end
            else # String
              field_or_opts
            end

    label
  end

  def show_pagination?(*_args)
    return false if view_context.render_grouped_response?

    @response.limit_value.positive?
  end

  def document_index_path_templates
    return ['exhibit_%<index_view_type>s'] if view_context.render_grouped_response?

    [
      'document_%<index_view_type>s',
      'catalog/document_%<index_view_type>s',
      'catalog/document_list'
    ].compact
  end

  def render_grouped_document_index(response = @response)
    slugs = response.aggregations[SolrDocument.exhibit_slug_field].items.map(&:value)
    exhibits = Spotlight::Exhibit.where(slug: slugs).sort_by { |e| slugs.index e.slug }
    view_context.render_document_index(exhibits)
  end

  def opensearch_catalog_url(*)
    view_context.spotlight.opensearch_search_across_url(*)
  end

  def start_over_path(*_args)
    root_path
  end

  ##
  # Override the Kaminari page_entries_info helper with our own, blacklight-aware
  # implementation. Why do we have to do this?
  #  - We need custom counting information for grouped results
  #  - We need to provide number_with_delimiter strings to i18n keys
  # If we didn't have to do either one of these, we could get away with removing
  # this entirely.
  #
  # @param [RSolr::Resource] collection (or other Kaminari-compatible objects)
  # @return [String]
  # Overridden from BL, move
  def page_entries_info(collection, entry_name: nil)
    entry_name = if entry_name
                   entry_name.pluralize(collection.size, I18n.locale)
                 else
                   collection.entry_name(count: collection.size).to_s.downcase
                 end

    entry_name = entry_name.pluralize unless collection.total_count == 1

    # grouped response objects need special handling
    end_num = if collection.respond_to?(:groups) && view_context.render_grouped_response?(collection)
                collection.groups.length
              else
                collection.limit_value
              end

    end_num = if collection.offset_value + end_num <= collection.total_count
                collection.offset_value + end_num
              else
                collection.total_count
              end

    case collection.total_count
    when 0
      t('search_across.pagination_info.no_items_found', entry_name:).html_safe
    when 1
      t('search_across.pagination_info.single_item_found', entry_name:).html_safe
    else
      t('search_across.pagination_info.pages', entry_name:,
                                               current_page: collection.current_page,
                                               num_pages: collection.total_pages,
                                               start_num: view_context.number_with_delimiter(collection.offset_value + 1),
                                               end_num: view_context.number_with_delimiter(end_num),
                                               total_num: view_context.number_with_delimiter(collection.total_count),
                                               count: collection.total_pages).html_safe
    end
  end
end
