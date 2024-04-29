# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Range limit widget', type: :feature, js: true do
  let(:exhibit) do
    create(:exhibit, published: true, slug: 'test-exhibit')
  end
  let(:admin) { create(:exhibit_admin, exhibit:) }

  before do
    login_as admin
    visit spotlight.search_exhibit_catalog_path(exhibit)
    page.driver.browser.manage.window.resize_to(1000, 400)
  end

  it 'has the date range facet' do
    expect(page).to have_button('Date Range')
  end
end
