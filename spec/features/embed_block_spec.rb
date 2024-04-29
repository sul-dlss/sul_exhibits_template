# frozen_string_literal: true

require 'rails_helper'
# Gem::Specificationfind_by_name is not a rails dynamic finder
require "#{Gem::Specification.find_by_name('blacklight-spotlight').gem_dir}/spec/support/features/test_features_helpers"

RSpec.feature 'Solr Documents Embed Block', type: :feature, js: true do
  include Spotlight::TestFeaturesHelpers

  let(:exhibit) { create(:exhibit) }
  let(:curator) { create(:exhibit_admin, exhibit:) }

  before do
    allow(Spotlight::Engine.config).to receive(:filter_resources_by_exhibit).and_return(false)
    sign_in curator
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

      save_page # rubocop:disable Lint/Debugger
      expect(page.find('.items-block iframe')['height']).to eq '600px'
    end

    it 'allows curators to set the maxheight paramter sent to the Embed' do
      visit spotlight.edit_exhibit_home_page_path(exhibit)

      add_widget('solr_documents_embed')

      fill_in_solr_document_block_typeahead_field(with: 'zy575vf8599')
      fill_in 'Maximum height of viewer (in pixels)', with: 300

      save_page # rubocop:disable Lint/Debugger
      expect(page.find('.items-block iframe')['height']).to eq '300px'
    end
  end
end
