module PagedScopes
  module Resources
    def resources_with_paged(*entities, &block)
      options = entities.extract_options!

      if paged_options = options.delete(:paged)
        resources_without_paged(*(entities.dup << options), &block)        
        
        paged_options = {} unless paged_options.is_a? Hash
        
        paged_as = paged_options.delete(:as)
        paged_name = paged_options.delete(:name)
        
        if paged_options.empty?
          if (options[:only] && options[:only].include?(:index)) || !(options[:except] && options[:except].include?(:index))
            paged_options.merge! :index => true
          end
          
          options[:collection].each_pair { |k,v| paged_options[k] = true if v == :get } if options[:collection].is_a? Hash
        end

        paged_options.each_pair do |action,page_options|
          page_options = {} unless page_options.is_a? Hash
          
          page_options.reverse_merge! :name => paged_name unless paged_name.blank?
          page_options.reverse_merge! :as => paged_as unless paged_as.blank?

          page_options[:only] = []
          
          preserved_options = ActionController::Resources::INHERITABLE_OPTIONS + [ :name_prefix, :path_prefix ]
          
          with_options(options.slice(*preserved_options)) do |map|
            map.resources_without_paged(page_options.delete(:name) || :pages, page_options) do |page|
              if action == :index
                page.resources(*(entities.dup << { :only => :index, :as => options[:as] }))
              else
                page.resources(*(entities.dup << { :only => [], :as => options[:as], :collection => { action => :get }}))
              end
            end
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
