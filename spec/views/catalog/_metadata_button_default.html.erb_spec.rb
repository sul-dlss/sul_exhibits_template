# frozen_string_literal: true

require 'rails_helper'

describe 'catalog/_metadata_button_default', type: :view do
  let(:document) { SolrDocument.new(modsxml: 'stuff', id: 'abc') }
  let(:current_exhibit) { create(:exhibit) }

  before do
    assign(:document, document)
  end

  context 'when modsxml is available' do
    it do
      expect(view).to receive_messages(current_exhibit:)
      render
      expect(rendered).to have_css 'a', text: 'More details »'
    end
  end

  context 'when modsxml is missing' do
    let(:document) { SolrDocument.new }

    it do
      render
      expect(rendered).not_to have_css 'a', text: 'More details »'
    end
  end
end
