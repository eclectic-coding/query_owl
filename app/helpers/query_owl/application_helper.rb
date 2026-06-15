module QueryOwl
  module ApplicationHelper
    def inline_styles
      dir = QueryOwl::Engine.root.join("app/assets/stylesheets/query_owl")
      css = dir.glob("_*.css").sort.map(&:read).join("\n")
      content_tag(:style, css.html_safe)
    end
  end
end
