module BreadcrumbHelper
  def breadcrumb_items
    items = [{ label: "Accueil", path: root_path }]

    if content_for?(:breadcrumbs)
      # Parse breadcrumb items set via content_for in views
      items
    else
      items
    end
  end
end
