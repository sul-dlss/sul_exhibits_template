# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ExhibitIndexer do
  subject(:indexer) { described_class.new(exhibit) }

  let(:solr_connection) { instance_spy('Blacklight::Solr::Connection') }
  let(:exhibit) { FactoryBot.create(:exhibit) }

  before do
    allow(described_class).to receive_messages(solr_connection:)
  end

  describe '#add' do
    it 'sends the add message to the solr connection with fields containing exhibit metadata' do
      indexer.add

      expect(solr_connection).to have_received(:add).with(
        hash_including(
          exhibit_slug_ssi: exhibit.slug,
          exhibit_title_tesim: exhibit.title
        )
      )
      expect(solr_connection).to have_received(:commit)
    end
  end

  describe '#delete' do
    it 'sends the delete_by_id message to the solr connection with the generated exhibit document id' do
      indexer.delete

      expect(solr_connection).to have_received(:delete_by_id).with("exhibit-#{exhibit.slug}")
      expect(solr_connection).to have_received(:commit)
    end
  end

  describe '#to_solr' do
    let(:to_solr) { indexer.to_solr }

    before do
      exhibit.subtitle = 'The Subtitle of This Exhibit'
      exhibit.description = <<-DESC
        Lorem ipsum dolor sit amet, consectetur adipiscing elit,
        sed do eiusmod tempor incididunt ut labore et dolore magna aliqua
      DESC
    end

    it 'generates its own document id' do
      expect(to_solr[:id]).to eq "exhibit-#{exhibit.slug}"
    end

    it 'includes a document type field to allow us to filter to/out just these documents' do
      expect(to_solr[:document_type_ssi]).to eq 'exhibit'
    end

    it 'includes metadata about the exhibit' do
      expect(to_solr[:exhibit_slug_ssi]).to eq exhibit.slug
      expect(to_solr[:exhibit_title_tesim]).to eq exhibit.title
      expect(to_solr[:exhibit_subtitle_tesim]).to eq exhibit.subtitle
      expect(to_solr[:exhibit_description_tesim]).to eq exhibit.description
    end
  end
end
