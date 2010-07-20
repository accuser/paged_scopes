module PagedScopes  
  module Collection
    module Attributes
      attr_writer :per_page
      
      COLLECTION = (Rails.version.to_i == 2 ? ActiveRecord::NamedScope::Scope : ActiveRecord::Relation)
      
      def per_page
        @per_page || case self
        when COLLECTION
          @proxy_scope.per_page
        when ActiveRecord::Associations::AssociationCollection
          @reflection.klass.per_page
        end
      end
    
      attr_writer :page_name
    
      def page_name
        @page_name || case self
        when COLLECTION
          @proxy_scope.page_name
        when ActiveRecord::Associations::AssociationCollection
          @reflection.klass.page_name
        else
          "Page"
        end
      end
    end
    
    include Attributes
  
    def pages
      @pages ||= returning(Class.new) do |klass|
        klass.send :include, Page
        klass.proxy = self
        klass.class_eval "alias :#{name.tableize} :page_scope"
        klass.instance_eval "alias :find_by_#{name.underscore} :find_by_object"
        klass.instance_eval "alias :find_by_#{name.underscore}! :find_by_object!"
      end
    end
  end
end

ActiveRecord::Base.extend PagedScopes::Collection::Attributes
ActiveRecord::Associations::AssociationCollection.send :include, PagedScopes::Collection
PagedScopes::Collection::COLLECTION.send :include, PagedScopes::Collection
