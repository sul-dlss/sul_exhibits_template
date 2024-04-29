# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Bibliography indexing', type: :feature do
  let(:exhibit) { create(:exhibit) }
  let(:curator) { create(:exhibit_admin, exhibit:) }

  before do
    sign_in curator
    ActiveJob::Base.queue_adapter = :inline
  end

  after do
    ActiveJob::Base.queue_adapter = :test
  end

  scenario 'indexes an item and makes it available to search' do
    visit spotlight.new_exhibit_resource_path(exhibit)
    click_link 'BibTeX'
    within '#external_resource_tab_1' do
      attach_file 'resource_bibtex_file', 'spec/fixtures/bibliography/article.bib'
      click_button 'Add items'
    end
    expect(page).to have_css 'h5', text: /Quelques/
    expect(page).to have_css '.alert-info', text: 'Your bibliography resource has been successfully created.'
  end

  context 'when disabled' do
    let(:exhibit) { create(:exhibit, slug: 'test-flag-exhibit-slug') }

    it 'is not visible' do
      visit spotlight.new_exhibit_resource_path(exhibit)
      click_link 'BibTeX'
      within '#external_resource_tab_1' do
        expect(page).not_to have_content 'Add items'
      end
      expect(page).to have_content 'This feature is not currently available for this exhibit.'
    end
  end
end
