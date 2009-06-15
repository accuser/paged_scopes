module PagedScopes
  module Index
    def index_of(object)
      find_scope = scope(:find) || {}
      primary_key_attribute = "#{table_name}.#{primary_key}"
      
      order_attributes = find_scope[:order].to_s.split(',').map(&:strip)
      order_operators = order_attributes.inject({}) do |hash, order_attribute|
        operator = order_attribute.slice!(/\s+(desc|DESC)$/) ? ">" : "<"
        order_attribute.slice!(/\s+(asc|ASC)$/)
        hash.merge(order_attribute => operator)
      end
      unless order_attributes.include? primary_key_attribute
        order_operators[primary_key_attribute] = "<"
        order_attributes << primary_key_attribute
      end
      
      attribute_selects = returning([]) do |selects|
        order_attributes.each_with_index do |order_attribute, n|
          selects << "#{order_attribute} AS order_attribute_#{n}"
        end
      end.join(', ')
      
      order_attribute_options = { :select => attribute_selects }
      order_attribute_options.merge!(:offset => 0) if find_scope[:offset]
      object_with_order_attributes = find(object.id, order_attribute_options)

      object_order_attributes = {}
      order_attributes.each_with_index do |order_attribute, n|
        object_order_attributes[order_attribute] = object_with_order_attributes.send("order_attribute_#{n}")
      end

      order_conditions = order_attributes.reverse.inject([ "", {}, 0 ]) do |args, order_attribute|
        string, hash, n = args
        symbol = "s#{n}".to_sym
        string = string.blank? ?
          "#{order_attribute} #{order_operators[order_attribute]} #{symbol.inspect}" :
          "#{order_attribute} #{order_operators[order_attribute]} #{symbol.inspect} OR (#{order_attribute} = #{symbol.inspect} AND (#{string}))"
        hash.merge!(symbol => object_order_attributes[order_attribute])
        [ string, hash, n + 1 ]
      end
      order_conditions.pop

      # order_conditions = order_attributes.reverse.inject([]) do |conditions, order_attribute|
      #   if conditions.empty?
      #     conditions = [ "#{order_attribute} #{order_operators[order_attribute]} ?", object_order_attributes[order_attribute] ]
      #   else
      #     conditions[0] = "#{order_attribute} #{order_operators[order_attribute]} ? OR (#{order_attribute} = ? AND (#{conditions[0]}))"
      #     conditions.insert 1, object_order_attributes[order_attribute]
      #     conditions.insert 1, object_order_attributes[order_attribute]
      #   end
      # end
      
      count_options = { :conditions => order_conditions, :distinct => true }
      count_options.merge!(:offset => 0) if find_scope[:offset]
      before_count = count(primary_key_attribute, count_options)
      if find_scope[:limit]
        before_count -= find_scope[:offset] if find_scope[:offset]
        raise ActiveRecord::RecordNotFound, "Couldn't find #{name} with ID=#{object.id}" if before_count < 0 || before_count >= find_scope[:limit]
      end
      
      before_count
    end

    def after(object)
      after_index = index_of(object) + 1
      if limit = scope(:find, :limit)
        after_index >= limit ? nil : first(:offset => after_index + (scope(:find, :offset) || 0))
      else
        first(:offset => after_index)
      end
    end

    def before(object)
      before_index = index_of(object) - 1
      if scope(:find, :limit)
        before_index < 0 ? nil : first(:offset => before_index + (scope(:find, :offset) || 0))
      else
        before_index < 0 ? nil : first(:offset => before_index)
      end
    end
  end
end

ActiveRecord::Base.send :extend, PagedScopes::Index
