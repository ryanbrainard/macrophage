module Macrophage
  class Page
    attr_reader :title, :path

    def initialize(title, path)
      @title = title
      @path = path
    end
  end

  Pages = [
      Macrophage::Page.new("Login", "/login"),
      Macrophage::Page.new("Applications", "/apps"),
      Macrophage::Page.new("Logout", "/logout")
  ]
end