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

    def window(options)
      results = []
      size = options[:size]
      extras = [ options[:extras] ].flatten.compact
      raise ArgumentError, "No window block supplied." unless block_given?
      return if @page.page_count < 2
      if @page.number - size > 1
        results << yield(:first, @path.call(@page.class.first)) if extras.include? :first
        if extras.include?(:previous) && offset_page = @page.offset(-2 * size - 1)
          results << yield(:previous, @path.call(offset_page))
        end
      end
      (-size..size).map { |offset| @page.offset(offset) }.compact.each do |page|
        results << yield( page, @path.call(page))
      end
      if @page.number + size < @page.page_count
        if extras.include?(:next) && offset_page = @page.offset(2 * size + 1)
          results << yield(:next, @path.call(offset_page))
        end
        results << yield(:last, @path.call(@page.class.last)) if extras.include? :last
      end
      results.join("\n")
    end
  end
end
