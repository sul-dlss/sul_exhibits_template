# frozen_string_literal: true

require 'rails_helper'

describe Spotlight::CatalogController do
  include ActiveJob::TestHelper
  routes { Spotlight::Engine.routes }

  let(:exhibit) { create(:exhibit) }
  let(:user) { create(:exhibit_admin, exhibit:) }

  before do
    sign_in user
  end

  describe '#manifest' do
    it 'sets appropriate CORS headers' do
      uploaded_resource = FactoryBot.create(:uploaded_resource)
      compound_id = uploaded_resource.compound_id

      perform_enqueued_jobs do
        uploaded_resource.save_and_index
      end

      get :manifest, params: { id: compound_id, exhibit_id: exhibit.id, locale: 'en' }

      expect(response.headers.to_h).to include 'Access-Control-Allow-Origin' => '*'
    end
  end
end
