# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BibliographyResourcesController, type: :controller do
  let(:resource) { double }
  let(:exhibit) { create(:exhibit) }
  let(:user) { create(:exhibit_admin, exhibit:) }
  let(:fixture_file) { fixture_file_upload('spec/fixtures/bibliography/article.bib') }
  let(:attributes) { { bibtex_file: fixture_file } }

  before do
    sign_in user
    allow(BibliographyResource).to receive(:find_or_initialize_by).and_return(resource)
    allow(resource).to receive(:update).with(bibtex_file: fixture_file.read)
    fixture_file.rewind
    allow(resource).to receive(:save_and_index).and_return(save_status)
  end

  describe '#create' do
    context 'when save is successful' do
      let(:save_status) { true }

      it 'goes to the exhibit' do
        post :create, params: { exhibit_id: exhibit.id, resource: attributes }

        expect(response).to redirect_to Spotlight::Engine.routes.url_helpers.admin_exhibit_catalog_path(exhibit)

        expect(resource).to have_received(:update)
        expect(resource).to have_received(:save_and_index)
      end
    end

    context 'when save is unsuccessful' do
      let(:save_status) { false }

      it 'goes to the exhibit' do
        post :create, params: { exhibit_id: exhibit.id, resource: attributes }

        expect(response).to redirect_to Spotlight::Engine.routes.url_helpers.new_exhibit_resource_path(exhibit)

        expect(resource).to have_received(:update)
        expect(resource).to have_received(:save_and_index)
      end
    end
  end

  describe '#update' do
    context 'when save is successful' do
      let(:save_status) { true }

      it 'goes to the exhibit' do
        patch :update, params: { exhibit_id: exhibit.id, resource: attributes }

        expect(response).to redirect_to Spotlight::Engine.routes.url_helpers.admin_exhibit_catalog_path(exhibit)

        expect(resource).to have_received(:update)
        expect(resource).to have_received(:save_and_index)
      end
    end

    context 'when save is unsuccessful' do
      let(:save_status) { false }

      it 'goes to the exhibit' do
        patch :update, params: { exhibit_id: exhibit.id, resource: attributes }

        expect(response).to redirect_to Spotlight::Engine.routes.url_helpers.new_exhibit_resource_path(exhibit)

        expect(resource).to have_received(:update)
        expect(resource).to have_received(:save_and_index)
      end
    end
  end
end
