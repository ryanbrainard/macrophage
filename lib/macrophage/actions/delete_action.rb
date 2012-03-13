module Macrophage::Actions
  class DeleteAction < BaseAction
    def label_present
      'delete'
    end

    def execute(heroku, app_name)
      heroku.delete_app(app_name)
    end
  end
end