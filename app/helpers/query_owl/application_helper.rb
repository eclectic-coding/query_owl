module QueryOwl
  module ApplicationHelper
    def inline_styles
      dir = QueryOwl::Engine.root.join("app/assets/stylesheets/query_owl")
      css = dir.glob("_*.css").sort.map(&:read).join("\n")
      content_tag(:style, css.html_safe)
    end

    def sort_th(label, column, current_sort, current_dir)
      active    = current_sort == column.to_s
      next_dir  = (active && current_dir == "asc") ? "desc" : "asc"
      indicator = active ? (current_dir == "asc" ? " ▲" : " ▼") : ""
      params    = request.query_parameters.merge("sort" => column, "direction" => next_dir)
      href      = "?" + params.to_query
      content_tag(:th) do
        link_to(
          "#{label}#{indicator}".html_safe,
          href,
          class: ["qo-sort-link", ("qo-sort-active" if active)].compact.join(" "),
          data: { turbo_frame: "qo-events" }
        )
      end
    end
  end
end
