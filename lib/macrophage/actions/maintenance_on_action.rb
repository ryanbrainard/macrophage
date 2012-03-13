module Macrophage::Actions
  class MaintenanceOnAction < BaseAction
    def label_present
      'enable maintenance mode'
    end

    def label_past
      'enabled maintenance mode'
    end

    def label_mod
      'for'
    end

    def execute(heroku, app_name)
      heroku.post_app_maintenance(app_name, 1)
    end
  end
end