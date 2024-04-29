# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchAcrossController, type: :controller do
  describe 'GET index' do
    context 'with a grouped response' do
      before do
        get :index, params: { q: 'some-query', group: true, sort: 'count' }
      end

      it 'hides the per page widget' do
        expect(controller.blacklight_config.index.collection_actions).not_to include(:per_page_widget)
      end

      it 'adds stub sort fields' do
        expect(controller.blacklight_config.sort_fields.length).to eq 2
        expect(controller.blacklight_config.sort_fields.keys).to eq %w(index count)
        expect(controller.blacklight_config.sort_fields.values.map(&:sort)).to eq ['', '']
      end

      it 'sorts the exhibits by count' do
        expect(controller.blacklight_config.facet_fields[SolrDocument.exhibit_slug_field].sort).to eq 'count'
      end
    end
  end

  describe '#render_grouped_response?' do
    it 'is false' do
      expect(controller).not_to be_render_grouped_response
    end

    context 'with the group param set' do
      before do
        controller.params[:group] = true
      end

      it 'is true' do
        expect(controller.render_grouped_response?).to eq true
      end
    end
  end

  describe '#url_for_document' do
    let(:document) do
      SolrDocument.new(id: 1, "#{SolrDocument.exhibit_slug_field}": ['a'])
    end

    it 'suppresses links for documents' do
      expect(controller.url_for_document(document)).to eq '#'
    end
  end

  describe '#link_to_document' do
    let(:document) do
      SolrDocument.new(id: 'SomeId1', "#{SolrDocument.exhibit_slug_field}": ['abc'])
    end

    it 'links to exhibit documents' do
      expect(controller.link_to_document(document, nil)).to eq 'SomeId1'
    end
  end

  describe '#show_pagination?' do
    it 'is suppressed for grouped responses' do
      allow(controller).to receive(:render_grouped_response?).and_return(true)
      expect(controller.show_pagination?).to eq false
    end
  end

  describe '#document_index_path_templates' do
    it 'injects custom exhibits document partials' do
      allow(controller).to receive(:render_grouped_response?).and_return(true)
      expect(controller.document_index_path_templates).to eq ['exhibit_%<index_view_type>s']
    end
  end

  describe '#render_grouped_document_index' do
    let(:response) do
      Blacklight::Solr::Response.new({
                                       facet_counts: {
                                         facet_fields: {
                                           "#{SolrDocument.exhibit_slug_field}": {
                                             a: 1,
                                             b: 3,
                                             c: 15
                                           }
                                         }
                                       }
                                     }, nil)
    end

    let!(:exhibits) do
      [
        create(:exhibit, slug: 'a'),
        create(:exhibit, slug: 'b'),
        create(:exhibit, slug: 'c')
      ]
    end

    let(:view_context) { instance_double('ViewContext', render_document_index: ->(*) { 'x' }) }

    it 'replaces solr results with exhibits from the database' do
      allow(controller).to receive(:view_context).and_return(view_context)
      controller.render_grouped_document_index(response)
      expect(view_context).to have_received(:render_document_index).with(exhibits)
    end
  end

  describe '#exhibit_tags_facet_query_config' do
    subject(:config) { controller.exhibit_tags_facet_query_config }

    before do
      create(:exhibit, slug: 'a', published: true, tag_list: %w(foo bar))
      create(:exhibit, slug: 'b', published: true, tag_list: ['bar'])
      create(:exhibit, slug: 'c', published: true, tag_list: %w(bar baz))
      create(:exhibit, slug: 'private', published: false, tag_list: %w(foo private))
    end

    it 'does nothing for unpublished exhibits' do
      expect(config.keys).not_to include 'private'
      expect(config['foo'][:fq]).not_to include 'private'
    end

    it 'constructs facet queries for each tag' do
      expect(config.keys).to match_array %w(foo bar baz)
      expect(config['foo'][:fq]).to eq "#{SolrDocument.exhibit_slug_field}:(a)"
      expect(config['bar'][:fq]).to eq "#{SolrDocument.exhibit_slug_field}:(a OR b OR c)"
      expect(config['baz'][:fq]).to eq "#{SolrDocument.exhibit_slug_field}:(c)"
    end
  end

  describe '#exhibit_visibility_query_config' do
    subject(:config) { controller.exhibit_visibility_query_config }

    let(:exhibit) do
      create(:exhibit, slug: 'mine', published: true, tag_list: ['bar'])
    end
    let(:user) { create(:exhibit_admin, exhibit:) }

    before do
      sign_in user
      create(:exhibit, slug: 'other')
    end

    it 'constructs facet queries for each exhibit the user can curate' do
      expect(config.keys).to match_array %i(private)
      expect(config[:private][:fq]).to include 'exhibit_mine_public_bsi:false'
      expect(config[:private][:fq]).not_to include 'exhibit_other_public_bsi:false'
    end
  end
end
