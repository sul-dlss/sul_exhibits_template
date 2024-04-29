# frozen_string_literal: true

require 'rails_helper'

RSpec.feature 'Search histories', type: :feature do
  let(:exhibit) { create(:exhibit) }

  before do
    allow(Search).to receive(:create).and_call_original

    # create a search in the history
    visit spotlight.search_exhibit_catalog_path(exhibit_id: exhibit.slug, q: 'article')

    # do a JSON or non-JSON query to see whether it's also added to the history
    visit spotlight.search_exhibit_catalog_path(exhibit_id: exhibit.slug,
                                                q: 'book',
                                                format:)
  end

  context 'when format is JSON' do
    let(:format) { 'json' }

    scenario 'second query is not added to search history' do
      expect(Search).to have_received(:create).once
    end
  end

  context 'when format is non-JSON' do
    let(:format) { 'html' }

    scenario 'second query is added to search history' do
      expect(Search).to have_received(:create).twice
    end
  end
end
