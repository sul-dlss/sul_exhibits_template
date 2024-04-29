# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SearchBuilder do
  subject(:builder) { described_class.new(scope).with(blacklight_params) }

  let(:exhibit) { create(:exhibit) }
  let(:scope) do
    instance_double('scope', blacklight_config:, current_exhibit: exhibit, search_state_class: nil)
  end
  let(:rows) { 999 }
  let(:blacklight_params) do
    {
      format: 'json',
      rows:
    }.with_indifferent_access
  end
  let(:blacklight_config) do
    Blacklight::Configuration.new.configure do |config|
      config.default_per_page = 99
      config.max_per_page_for_api = 999
    end
  end

  before :all do
    # remove Advanced Search plugin processing due to its required configuration
    described_class.default_processor_chain.delete(:add_advanced_parse_q_to_solr)
    described_class.default_processor_chain.delete(:add_advanced_search_to_solr)
  end

  after :all do
    # restore
    described_class.default_processor_chain << :add_advanced_parse_q_to_solr
    described_class.default_processor_chain << :add_advanced_search_to_solr
  end

  it 'allows up to max per page' do
    expect(builder.to_hash).to include(rows: 999)
  end

  context 'JSON API is over limit' do
    let(:rows) { 999_999 }

    it 'cannot exceed max per page' do
      expect(builder.to_hash).to include(rows: 999)
    end
  end

  context 'JSON API configuration is omitted' do
    let(:blacklight_config) do
      Blacklight::Configuration.new.configure do |config|
        config.default_per_page = 99
      end
    end

    let(:rows) { 999_999 }

    it 'cannot exceed max per page' do
      expect(builder.to_hash).to include(rows: 1_000)
    end
  end

  context 'JSON API omits limit' do
    let(:blacklight_params) do
      {
        format: 'json'
      }.with_indifferent_access
    end

    it 'becomes config.default_per_page' do
      expect(builder.to_hash).to include(rows: 99)
    end
  end

  context 'non-JSON API is over limit' do
    let(:blacklight_params) { { q: 'my query', rows: }.with_indifferent_access } # omit format

    it 'cannot exceed config.max_per_page' do
      expect(builder.to_hash).to include(rows: 100)
    end
  end

  it 'removes exhibit records' do
    expect(builder.to_hash[:fq]).to include '-document_type_ssi:exhibit'
  end
end
