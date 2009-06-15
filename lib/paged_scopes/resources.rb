module PagedScopes
  module Resources
    def resources_with_paged(*entities, &block)
      options = entities.extract_options!
      if page_options = options.delete(:paged)
        resources_without_paged(*(entities.dup << options), &block)
        page_options = {} unless page_options.is_a? Hash
        page_name = page_options.delete(:name)
        page_options.slice!(:as, :name)
        page_options.merge!(:only => :none)
        preserved_options = ActionController::Resources::INHERITABLE_OPTIONS + [ :name_prefix, :path_prefix ]
        with_options(options.slice(*preserved_options)) do |map|
          map.resources_without_paged(page_name || :pages, page_options) do |page|
            page.resources(*(entities.dup << { :only => :index }))
          end
        end
      else
        resources_without_paged(*(entities << options), &block)
      end
    end
    
    def self.included(base)
      base.class_eval do
        alias_method_chain :resources, :paged
      end
    end
  end
end

if defined? ActionController::Resources
  ActionController::Resources.send :include, PagedScopes::Resources
end
