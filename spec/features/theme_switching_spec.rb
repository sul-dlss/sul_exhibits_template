# frozen_string_literal: true

require 'rails_helper'

describe 'Theme switching', type: :feature do
  let(:exhibit) { create(:exhibit) }
  let(:user) { create(:exhibit_admin, exhibit:) }

  before { sign_in user }

  context 'Parker' do
    it 'allows the Parker theme to be selected', js: true do
      allow(Settings).to receive(:exhibit_themes).and_return(exhibit.slug => %w(parker default))
      visit spotlight.exhibit_dashboard_path(exhibit)

      expect(page).to have_css('#global-footer', visible: :visible)
      expect(page).to have_css('#sul-footer', visible: :visible)

      within('#sidebar') { click_link 'Appearance' }

      choose 'Parker'

      click_button 'Save changes'

      expect(page).to have_css('#global-footer', visible: :hidden)
      expect(page).to have_css('#sul-footer', visible: :hidden)
    end
  end
end
