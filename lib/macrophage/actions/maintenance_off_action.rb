module Macrophage::Actions
  class MaintenanceOffAction < BaseAction
    def label_present
      'disable maintenance mode'
    end

    def label_past
      'disabled maintenance mode'
    end

    def label_mod
      'for'
    end

    def execute(heroku, app_name)
      heroku.post_app_maintenance(app_name, 0)
    end
  end
end