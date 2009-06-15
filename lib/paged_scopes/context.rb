module PagedScopes
  module Context
    extend ActiveSupport::Memoizable
    
    def self.included(base)
      base.extend ClassMethods
      class << base
        alias_method_chain :find, :context
      end
    end
    
    module ClassMethods
      def find_with_context(*args)
        returning find_without_context(*args) do |results|
          found_scope, found_options = scope(:find), args.extract_options!
          [ results ].flatten.compact.each do |result|
            result.instance_variable_set "@found_scope", found_scope
            result.instance_variable_set "@found_options", found_options
          end
        end
      end
    end
    
    def previous
      self.class.scoped(@found_scope).scoped(@found_options).before(self)
    end
    
    def next
      self.class.scoped(@found_scope).scoped(@found_options).after(self)
    end
    
    memoize :previous, :next
  end
end

ActiveRecord::Base.send :include, PagedScopes::Context
