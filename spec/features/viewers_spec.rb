# frozen_string_literal: true

require 'rails_helper'
include JavascriptFeatureHelpers

describe 'Viewers', type: :feature do
  let(:exhibit) { create(:exhibit, slug: 'default-exhibit') }
  let(:user) { nil }

  before do
    sign_in user
  end

  context 'an authorized user' do
    let(:user) { create(:exhibit_admin, exhibit:) }

    it 'sees the default configuration' do
      visit spotlight.exhibit_dashboard_path(exhibit)

      within('#sidebar') do
        click_link 'Viewers'
      end

      expect(find_field('SUL-Embed')[:checked]).to eq 'checked'
    end

    it 'can edit the viewers configuration' do
      visit spotlight.exhibit_dashboard_path(exhibit)

      within('#sidebar') do
        click_link 'Viewers'
      end

      within '#item-detail-page' do
        choose 'Mirador 3'
        click_button 'Save changes'
      end

      expect(find_field('Mirador 3')[:checked]).to eq 'checked'
    end

    it 'includes breadcrumbs on the edit page' do
      visit edit_exhibit_viewers_path(exhibit)

      within('ul.breadcrumb') do
        expect(page).to have_link 'Home'
        expect(page).to have_link 'Configuration'
        expect(page).to have_css('li.active', text: 'Viewers')
      end
    end

    it 'allows updating a custom manifest URL pattern' do
      visit edit_exhibit_viewers_path(exhibit)

      within '#iiif-manifest' do
        fill_in 'viewer_custom_manifest_pattern', with: 'https://example.com/manifest/{id}'
        click_button 'Save changes'
      end

      expect(find_field('IIIF manifest URL pattern').value).to eq 'https://example.com/manifest/{id}'
    end

    it 'is invalid without {id}' do
      visit edit_exhibit_viewers_path(exhibit)

      within '#iiif-manifest' do
        fill_in 'viewer_custom_manifest_pattern', with: 'https://poorlyformed.com/manifest'
        click_button 'Save changes'
      end

      expect(page).to have_css '.alert.alert-warning', text: 'There was a problem updating the viewer settings'
      expect(find_field('IIIF manifest URL pattern').value).to be_nil
    end
  end

  describe 'rendered viewer' do
    let(:feature_page) { FactoryBot.create(:feature_page, exhibit:) }
    let(:admin) { FactoryBot.create(:exhibit_admin, exhibit:) }

    before do
      exhibit.required_viewer.viewer_type = 'mirador3'
      exhibit.required_viewer.save
      login_as admin
    end

    it 'renders configured viewer on show page' do
      visit spotlight.exhibit_solr_document_path(exhibit, 'hj066rn6500')
      expect(page).to have_css 'iframe[src*=embed]'
      expect(page).not_to have_css '.oembed-widget'
    end
    # rubocop:disable RSpec/ExampleLength

    pending 'renders default viewer on configured widget feature page', js: true do
      visit spotlight.edit_exhibit_feature_page_path(exhibit, feature_page)

      add_widget 'solr_documents' # the "Item Row" widget

      fill_in_typeahead_field with: 'hj066rn6500'

      expect(page).to have_selector '.panel'

      within('.panel') do
        expect(page).to have_content(/Image \d of \d/)
        expect(page).to have_link 'Change'
      end

      save_page # rubocop:disable Lint/Debugger

      expect(page).not_to have_css 'iframe[src*=embed]'
      expect(page).to have_css '.oembed-widget'
    end
    # rubocop:enable RSpec/ExampleLength
  end

  describe 'PURL link' do
    it 'does not include the protocol' do
      visit spotlight.exhibit_solr_document_path(exhibit, 'hj066rn6500')

      expect(page).to have_css('a', text: %r{^purl\.stanford\.edu/hj066rn6500})
    end

    context 'Parker Theme' do
      before do
        allow(Settings).to receive(:exhibit_themes).and_return(exhibit.slug => %w(parker default))
        exhibit.theme = 'parker'
        exhibit.save!
      end

      it 'hides the PURL link', js: true do
        visit spotlight.exhibit_solr_document_path(exhibit, 'hj066rn6500')

        expect(page).not_to have_css('.purl-link', visible: :visible)
      end
    end
  end
end
