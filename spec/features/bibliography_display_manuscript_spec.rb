# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Bibliography display on the manuscript show page', type: :feature do
  let(:exhibit) { create(:exhibit, slug: 'default-exhibit') }
  let(:resource_id) { 'gk885tn1705' }
  let(:bibtex_file) { 'spec/fixtures/bibliography/{article,incollection}.bib' }

  before do
    ActiveJob::Base.queue_adapter = :inline # block until indexing has committed

    bibtex_data = Dir.glob(bibtex_file).collect do |fn|
      File.read(fn)
    end.join("\n")

    # we index some bibliography records that have links to our resource
    bib = BibliographyResource.new(bibtex_file: bibtex_data, exhibit:)
    bib.save_and_index

    # render the resource show page
    visit spotlight.exhibit_solr_document_path(exhibit_id: exhibit.slug, id: resource_id)
  end

  after :all do
    ActiveJob::Base.queue_adapter = :test # restore
  end

  scenario 'bibliography element data required by async loader' do
    expect(page).to have_css('div.record-metadata-section[data-path="/default-exhibit/catalog"]', visible: :hidden)
    expect(page).to have_css("div.record-metadata-section[data-parentid=\"#{resource_id}\"]", visible: :hidden)
    expect(page).to have_css(
      'div.record-metadata-section[data-sort="author_sort asc, pub_year_isi asc, title_sort asc"]', visible: :hidden
    )
  end

  scenario 'async loading of the sorted, formatted bibliography', js: true do # rubocop: disable RSpec/ExampleLength
    within '.record-metadata-section' do
      within '.bibliography-list' do
        # must be sorted correctly
        within 'p:nth-child(1)' do
          expect(page).to have_content('Whatley, E. G. 1986.')
          expect(page).to have_css('a[href$="/default-exhibit/catalog/EI8BRRXB"]')
        end
        within 'p:nth-child(2)' do
          expect(page).to have_content('Wille, Clara. 2004.')
          expect(page).to have_css('a[href$="/default-exhibit/catalog/QTWBAWKX"]')
        end
      end
    end
  end

  context 'large bibliographies' do
    let(:resource_id) { 'xy658qf4887' }
    let(:bibtex_file) { 'spec/fixtures/bibliography/many_bibliographies.bib' }

    scenario 'are togglable', js: true do
      within '.record-metadata-section' do
        within '.bibliography-list' do
          expect(page).to have_css('p.bibliography-body', count: 3, visible: :visible)

          click_button 'Expand bibliography'

          expect(page).to have_css('p.bibliography-body', count: 6, visible: :visible)

          click_button 'Collapse bibliography'

          expect(page).to have_css('p.bibliography-body', count: 3, visible: :visible)
        end
      end
    end
  end

  context 'when there are no associated bibliography documents returned', js: true do
    let(:resource_id) { 'wd297xz1362' }

    scenario 'the bibliography section is rendered (but not visible)' do
      expect(page).to have_css('.record-metadata-section', visible: :hidden)
      expect(page).not_to have_css('h3', text: 'Bibliography', visible: :visible)

      # No documents are added
      expect(page).not_to have_css('.bibliography-list')
    end
  end
end
