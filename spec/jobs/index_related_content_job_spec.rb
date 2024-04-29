# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IndexRelatedContentJob do
  describe '#perform' do
    let(:exhibit) { create(:exhibit) }
    let(:harvester) { DorHarvester.new(exhibit:) }
    let(:enqueuer) { instance_double(IiifCanvasIndexer, index_canvases: []) }

    it do
      allow(IiifCanvasIndexer).to receive(:new).and_return(enqueuer)
      subject.perform(harvester, 'abc123')
    end
  end
end
