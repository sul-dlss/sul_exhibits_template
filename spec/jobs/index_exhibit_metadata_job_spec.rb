# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IndexExhibitMetadataJob do
  let(:exhibit) { FactoryBot.create(:exhibit) }
  let(:indexer) { instance_spy('ExhibitIndexer') }

  before do
    allow(ExhibitIndexer).to receive(:new).with(exhibit).and_return(indexer)
  end

  context 'when the action is add' do
    it 'sends the add message to the ExhibitIndexer' do
      subject.perform(exhibit:, action: 'add')

      expect(indexer).to have_received(:add)
    end
  end

  context 'when the action is delete' do
    it 'sends the delete message to the ExhibitIndexer' do
      subject.perform(exhibit:, action: 'delete')

      expect(indexer).to have_received(:delete)
    end
  end
end
