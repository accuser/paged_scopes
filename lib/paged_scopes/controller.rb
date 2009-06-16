module PagedScopes
  module Controller
    def get_page_for(collection_name, options = {})
      callback_method = "get_page_for_#{collection_name}"
      define_method callback_method do
        collection = instance_variable_get("@#{collection_name.to_s.pluralize}")
        raise RuntimeError, "no @#{collection_name.to_s.pluralize} collection was set" unless collection
        object = instance_variable_get("@#{collection_name.to_s.singularize}")
        collection.per_page = options[:per_page] if options[:per_page]
        collection.page_name = options[:name] if options[:name]
        page = collection.pages.from_params(params) || (object && collection.pages.find_by_object(object)) || collection.pages.first
        page.paginator.set_path { |pg| send(options[:path], pg) } if options[:path]
        instance_variable_set("@#{collection.pages.name.underscore}", page)
      end
      protected callback_method
      before_filter callback_method
    end
  end
end

if defined? ActionController::Base
  ActionController::Base.extend PagedScopes::Controller
end
