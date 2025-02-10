# frozen_string_literal: true

require 'rails_helper'
# Gem::Specificationfind_by_name is not a rails dynamic finder
require "#{Gem::Specification.find_by_name('blacklight-spotlight').gem_dir}/spec/support/features/test_features_helpers"

RSpec.feature 'Solr Documents Embed Block', js: true do
  include JavascriptFeatureHelpers
  include Spotlight::TestFeaturesHelpers

  let(:exhibit) { create(:exhibit) }
  let(:curator) { create(:exhibit_admin, exhibit: exhibit) }

  before do
    allow(Spotlight::Engine.config).to receive(:filter_resources_by_exhibit).and_return(false)
    sign_in curator

    stub_request(:get, 'http://purl.stanford.edu/embed.json')
      .with(query: hash_including({ 'url' => 'https://purl.stanford.edu/zy575vf8599', 'maxheight' => '600' }))
      .to_return(status: 200, body: File.read(File.join(FIXTURES_PATH, 'purl_embed/600/zy575vf8599.json')))

    stub_request(:get, 'http://purl.stanford.edu/embed.json')
      .with(query: hash_including({ 'url' => 'https://purl.stanford.edu/zy575vf8599', 'maxheight' => '300' }))
      .to_return(status: 200, body: File.read(File.join(FIXTURES_PATH, 'purl_embed/300/zy575vf8599.json')))
  end

  describe 'block editing form' do
    it 'has a number field to input the hight (with a default placeholder)' do
      visit spotlight.edit_exhibit_home_page_path(exhibit)

      add_widget('solr_documents_embed')

      expect(page).to have_css('label', text: 'Maximum height of viewer (in pixels)')
      number_input = page.find('input[type="number"][placeholder]')
      expect(number_input['placeholder']).to eq '600'
      expect(number_input.value).to eq ''

      fill_in_solr_document_block_typeahead_field(with: 'zy575vf8599')

      save_and_verify_page

      expect(page.find('.items-block iframe')['height']).to eq '600px'
    end

    it 'allows curators to set the maxheight paramter sent to the Embed' do
      visit spotlight.edit_exhibit_home_page_path(exhibit)

      add_widget('solr_documents_embed')

      fill_in_solr_document_block_typeahead_field(with: 'zy575vf8599')
      fill_in 'Maximum height of viewer (in pixels)', with: 300

      save_and_verify_page
      expect(page.find('.items-block iframe')['height']).to eq '300px'
    end

    it 'allows curators to select the image area' do
      visit spotlight.edit_exhibit_home_page_path(exhibit)

      add_widget('solr_documents_embed')

      fill_in_solr_document_block_typeahead_field(with: 'zy575vf8599')

      expect(page).to have_css('.select-image-area')
    end
  end
end
