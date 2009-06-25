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
      # return if one page...?
      raise ArgumentError, "No window block supplied." unless block_given?
      raise ArgumentError, "please specify a :inner option" unless inner = options[:inner]
      outer = options[:outer] || 0
      extras = [ options[:extras] ].flatten.compact
      numbers = (@page.number-inner..@page.number+inner).to_a
      1.upto(outer) { |n| numbers << n << @page.page_count-n+1 }
      numbers = numbers.uniq.sort.select { |n| n.between?(1, @page.page_count) }
      returning [] do |results|
        results << yield(:first, @page.first? ? nil : @path.call(@page.class.first), {}) if extras.include?(:first)
        results << yield(:previous, @page.first? ? nil : @path.call(@page.previous), {}) if extras.include?(:previous)
        numbers.zip([nil]+numbers, numbers[1..-1]) do |number, prev_number, next_number|
          page = @page.class.find(number)
          path = page == @page ? nil : @path.call(page)
          opts = {}
          opts[:selected] = page == @page
          opts[:gap_before] = prev_number ? prev_number < number - 1 : false
          opts[:gap_after] = next_number ? next_number > number + 1 : false
          results << yield(page, path, opts)
        end        
        results << yield(:next, @page.last? ? nil : @path.call(@page.next), {}) if extras.include?(:next)
        results << yield(:last, @page.last? ? nil : @path.call(@page.class.last), {}) if extras.include?(:last)
      end.join("\n")
    end
  end
end
