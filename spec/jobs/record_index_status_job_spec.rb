# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RecordIndexStatusJob do
  describe '#perform' do
    let(:exhibit) { create(:exhibit) }
    let(:harvester) { DorHarvester.new(exhibit:) }

    it 'creates a new sidecar with a status entry' do
      expect do
        subject.perform(harvester, 'xyz', ok: true)
      end.to change(Spotlight::SolrDocumentSidecar, :count).by(1)

      expect(Spotlight::SolrDocumentSidecar.last.index_status).to include ok: true
    end

    it 'updates an existing sidecar with a status entry' do
      subject.perform(harvester, 'xyz', ok: false)

      expect do
        subject.perform(harvester, 'xyz', ok: true)
      end.not_to change(Spotlight::SolrDocumentSidecar, :count)

      expect(Spotlight::SolrDocumentSidecar.last.index_status).to include ok: true
    end
  end
end
