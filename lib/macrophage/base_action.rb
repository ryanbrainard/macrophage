module Macrophage
  class BaseAction
    def label_present
      raise 'Abstract: Implement in subclass'
    end

    def label_past
      label_present + 'd'
    end

    def label_mod
      ''
    end

    def execute(heroku, app_name)
      raise 'Abstract: Implement in subclass'
    end
  end
end