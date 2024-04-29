# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Cited manuscripts display on the bibliography show page', type: :feature do
  let(:exhibit) { create(:exhibit, slug: 'default-exhibit') }
  let(:resource_id) { 'QTWBAWKX' }
  let(:citations_string) { '["gs233db8425", "gk885tn1705", "hj066rn6500"]' }
  let(:bibtex_data) do
    Dir.glob('spec/fixtures/bibliography/{article,incollection}.bib').collect do |fn|
      File.read(fn)
    end.join("\n")
  end

  before do
    ActiveJob::Base.queue_adapter = :inline # block until indexing has committed

    # we index some bibliography records that have links to our resource
    bib = BibliographyResource.new(bibtex_file: bibtex_data, exhibit:)
    bib.save_and_index

    # render the resource show page
    visit spotlight.exhibit_solr_document_path(exhibit_id: exhibit.slug, id: resource_id)
  end

  after :all do
    ActiveJob::Base.queue_adapter = :test # restore
  end

  scenario 'cited documents element data required by async loader comes through to front end' do
    expect(page).to have_css('div.record-metadata-section[data-path="/default-exhibit/catalog"]')
    expect(page).to have_css("div.record-metadata-section[data-parentid=\"#{resource_id}\"]")
    expect(page).to have_css('div.record-metadata-section[data-documentids]')
    expect(page.find('div.record-metadata-section[data-documentids]')['data-documentids']).to eq(citations_string)
  end

  scenario 'async loading of the sorted, formatted bibliography', js: true do
    within '.record-metadata-section' do
      within '.cited-documents-list' do
        # can appear in any order
        expect(page).to have_content('Afrique Physique')
        expect(page).to have_css('a[href$="gk885tn1705"]')
        expect(page).not_to have_content('The Peterborough Psalter and Bestiary.')
        expect(page).not_to have_css('a[href$="gs233db8425"]')
        expect(page).to have_content('Posesiones españolas en')
        expect(page).to have_css('a[href$="hj066rn6500"]')
      end
    end
  end
end
