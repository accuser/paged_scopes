module PagedScopes
  class Paginator
    attr_reader :page

    def initialize(page)
      @page = page
    end

    def set_path(&block)
      @path = block
    end
    
    def path
      @path || raise(RuntimeError, "No path proc supplied.")
    end

    def previous
      path.call(@page.previous) unless @page.first?
    end

    def next
      path.call(@page.next) unless @page.last?
    end

    # def window(options)
    #   raise ArgumentError, "please specify a :inner option" unless size = options[:inner]
    #   :outer
    #   extras = [ options[:extras] ].flatten.compact
    #   raise ArgumentError, "No window block supplied." unless block_given?
    #   returning [] do |results|
    #     results << yield(:first, @page.first? ? nil : @path.call(@page.class.first)) if extras.include?(:first)
    #     results << yield(:previous, @page.first? ? nil : @path.call(@page.previous)) if extras.include?(:previous)
    #     (-size..size).map { |offset| @page.offset(offset) }.compact.each do |page|
    #       results << yield(page, @path.call(page))
    #     end
    #     results << yield(:next, @page.last? ? nil : @path.call(@page.next)) if extras.include?(:next)
    #     results << yield(:last, @page.last? ? nil : @path.call(@page.class.last)) if extras.include?(:last)
    #   end.join("\n")
    # end

    def window(options)
      # return if one page...?
      raise ArgumentError, "please specify a :inner option" unless inner = options[:inner]
      outer = options[:outer] || 0
      extras = [ options[:extras] ].flatten.compact
      raise ArgumentError, "No window block supplied." unless block_given?
      returning [] do |results|
        results << yield(:first, @page.first? ? nil : @path.call(@page.class.first)) if extras.include?(:first)
        results << yield(:previous, @page.first? ? nil : @path.call(@page.previous)) if extras.include?(:previous)
        numbers = (@page.number-inner..@page.number+inner).to_a
        outer.times { |n| numbers.unshift(n+1).push(@page.page_count-n) }
        numbers.uniq.sort.select do |number|
          number.between?(1, @page.page_count)
        end.inject(nil) do |previous, number|
          results << yield(:separator, nil) if previous && previous < number - 1
          page = @page.class.find(number)
          results << yield(page, page == @page ? nil : @path.call(page))
          number
        end        
        results << yield(:next, @page.last? ? nil : @path.call(@page.next)) if extras.include?(:next)
        results << yield(:last, @page.last? ? nil : @path.call(@page.class.last)) if extras.include?(:last)
      end.join("\n")
    end
  end
end
