# frozen_string_literal: true

# This unpleasantness allows us to include the upstream controller before overriding it
spotlight_path = Gem::Specification.find_by_name('blacklight-spotlight').full_gem_path
require_dependency File.join(spotlight_path, 'app/controllers/spotlight/exhibits_controller')

module Spotlight
  # Override the upstream HomePagesController in order to inject range limit behaviors
  class ExhibitsController
    def search_action_url(*)
      main_app.search_search_across_url(*)
    end

    def blacklight_config
      SearchAcrossController.blacklight_config
    end
  end
end
