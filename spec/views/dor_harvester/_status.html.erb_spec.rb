# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'dor_harvester/_status.html.erb', type: :view do
  let(:exhibit) { create(:exhibit) }
  let(:harvester) { DorHarvester.new(druid_list: '', exhibit:) }

  context 'with status information' do
    before do
      RecordIndexStatusJob.perform_now(harvester, 'okdruid', ok: true)
      RecordIndexStatusJob.perform_now(harvester, 'baddruid', ok: false, message: 'broken')
      harvester.collections['collectiondruid'] = { size: 52 }
    end

    it 'displays the object status' do
      render partial: 'dor_harvester/status', locals: { harvester: }
      expect(rendered).to have_content('Object druids')
      expect(rendered).to have_content(/okdruid\s+Published/)
      expect(rendered).to have_selector '.danger', text: /baddruid\s+broken/
    end

    it 'displays the collection status' do
      render partial: 'dor_harvester/status', locals: { harvester: }
      expect(rendered).to have_content('Collection druids')
      expect(rendered).to have_content(/collectiondruid\s+52/)
    end
  end

  context 'without status information' do
    it 'displays an empty status' do
      render partial: 'dor_harvester/status', locals: { harvester: }
      expect(rendered).not_to have_selector '#sdr-status-inner-items'
      expect(rendered).not_to have_selector '#sdr-status-inner-collections'
    end
  end
end
