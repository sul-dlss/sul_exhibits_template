# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchAcrossHelper, type: :helper do
  describe '#search_without_group' do
    let(:search_state) do
      instance_double(
        'Blacklight::SearchState',
        params_for_search: { group: true }
      )
    end

    it 'removes the group key/value' do
      expect(helper).to receive_messages(
        search_state:
      )
      expect(helper.search_without_group).to eq({})
    end
  end

  describe '#search_with_group' do
    let(:search_state) do
      instance_double(
        'Blacklight::SearchState',
        params_for_search: {}
      )
    end

    it 'removes the group key/value' do
      expect(helper).to receive_messages(
        search_state:
      )
      expect(helper.search_with_group).to eq group: true
    end
  end

  describe '#exhibit_search_state_params' do
    it 'simplifies the search state to just the stuff that makes sense within an exhibit' do
      bad_params = { group: true, page: 15, f: { whatever: 'bad', SolrDocument.exhibit_slug_field => 'some-slug' } }
      good_params = { q: 'some search', f: { format_main_ssim: ['Book'] } }
      search_across_params = ActionController::Parameters.new(bad_params.deep_merge(good_params))
      search_across_params.permit!

      search_state = Blacklight::SearchState.new(search_across_params, nil, nil)

      expect(helper.exhibit_search_state_params(search_state)).to eq good_params.deep_stringify_keys
    end
  end

  describe '#unpublished_badge' do
    it 'returns an badge w/ the Unpublished text' do
      expect(Capybara.string(helper.unpublished_badge)).to have_css('span.badge.badge-warning', text: 'Unpublished')
    end

    it 'allows a css class to be passed in (that is appended)' do
      expect(
        Capybara.string(helper.unpublished_badge(class: 'unpublished'))
      ).to have_css('span.badge.badge-warning.unpublished')
    end

    it 'allows other HTML attributes to be passed in' do
      expect(
        Capybara.string(helper.unpublished_badge(title: 'The Title'))
      ).to have_css('span.badge.badge-warning[title="The Title"]')
    end
  end

  describe '#render_exhibit_title' do
    let(:blacklight_config) { SearchAcrossController.blacklight_config }
    let(:response) do
      {
        response: {
          docs: [
            { "#{SolrDocument.exhibit_slug_field}": ['abc'] },
            { "#{SolrDocument.exhibit_slug_field}": %w(abc 123 private) },
            { "#{SolrDocument.exhibit_slug_field}": ['private'] }
          ]
        }
      }
    end

    let(:doc) do
      SolrDocument.new(
        id: 1,
        SolrDocument.exhibit_slug_field => %w(abc 123 private)
      )
    end
    let(:current_ability) { Ability.new(User.new) }

    before do
      assign(:response, Blacklight::Solr::Response.new(response, nil, blacklight_config:))
      allow(helper).to receive(:current_ability).and_return(current_ability)

      create(:exhibit, slug: 'abc', title: 'Alphabet')
      create(:exhibit, slug: '123', title: 'Numbers')
      create(:exhibit, slug: 'private', published: false, title: 'Secret')
    end

    it 'links to published exhibits by title' do
      actual = Capybara.string(helper.render_exhibit_title(document: doc, value: %w(abc 123 private)))
      expect(actual).to have_link text: 'Alphabet', href: spotlight.exhibit_solr_document_path(exhibit_id: 'abc', id: 1)
      expect(actual).to have_link text: 'Numbers', href: spotlight.exhibit_solr_document_path(exhibit_id: '123', id: 1)
      expect(actual).to have_css 'br'
      expect(actual).not_to have_link text: 'Secret'
    end

    context 'unpublished exhibits' do
      before do
        allow(helper).to receive(:accessible_exhibits_from_search_results).and_return(Spotlight::Exhibit.all)
      end

      it 'includes an Unpublished badge for unpublished exhibits' do
        titles = helper.render_exhibit_title(document: doc, value: %w(abc 123 private))
        expect(titles).to match(%r{>Secret</a> <span class="badge badge-warning})
      end
    end
  end

  describe '#render_exhibit_title_facet' do
    let(:blacklight_config) { SearchAcrossController.blacklight_config }
    let(:response) do
      {
        facet_counts: {
          facet_fields: {
            "#{SolrDocument.exhibit_slug_field}": {
              a: 1,
              b: 3,
              c: 15
            }
          }
        }
      }
    end

    let(:current_ability) { Ability.new(User.new) }

    before do
      assign(:response, Blacklight::Solr::Response.new(response, nil, blacklight_config:))
      allow(helper).to receive(:current_ability).and_return(current_ability)

      create(:exhibit, slug: 'a', title: 'Alphabet')
      create(:exhibit, slug: 'b', published: false, title: 'Secret')
    end

    it 'translates exhibit slugs in the facets to titles' do
      expect(helper.render_exhibit_title_facet('a')).to eq 'Alphabet'
    end

    it 'hides private exhibits' do
      expect(helper.render_exhibit_title_facet('b')).to be_blank
    end
  end

  describe '#exhibit_metadata' do
    let(:response) do
      {
        response: {
          docs: [
            { "#{SolrDocument.exhibit_slug_field}": ['abc'] },
            { "#{SolrDocument.exhibit_slug_field}": %w(abc xyz) },
            { "#{SolrDocument.exhibit_slug_field}": ['private'] }
          ]
        }
      }
    end
    let(:blacklight_config) { SearchAcrossController.new.blacklight_config }
    let(:current_ability) { Ability.new(User.new) }

    before do
      assign(:response, Blacklight::Solr::Response.new(response, nil, blacklight_config:))
      create(:exhibit, slug: 'abc')
      create(:exhibit, slug: 'xyz')
      create(:exhibit, slug: 'private', published: false)
      allow(helper).to receive(:current_ability).and_return(current_ability)
    end

    it 'retrieves exhibit data from the database' do
      expect(helper.exhibit_metadata.keys).to match_array(%w(abc xyz))
    end
  end
end
