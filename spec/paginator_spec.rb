require 'spec_helper'

describe "Paginator" do
  before(:each) do
    @articles = Article.scoped({})
    @articles.per_page = 3
    @pages = @articles.pages
    @size = 2 # window size
    @page_count = @pages.count
    (@page_count >= 14).should be_true # window specs won't work otherwise
    @path = lambda { |page| "/path/to/page/#{page.to_param}" }
  end
  
  it "should raise an error if the paginator path is not set" do
    lambda { @pages.first.paginator.next }.should raise_error(RuntimeError)
  end
  
  context "for the first page" do
    before(:each) do
      @page = @pages.first
      @paginator = @page.paginator
      @paginator.set_path(&@path)
    end

    it "should call the path proc with the next page when #next is called" do
      @path.should_receive(:call).with(@page.next)
      @paginator.next
    end
    
    it "should not call the path proc when #previous is called" do
      @path.should_not_receive(:call)
      @paginator.previous.should be_nil
    end
  end

  context "for the last page" do
    before(:each) do
      @page = @pages.first
      @paginator = @page.paginator
      @paginator.set_path(&@path)
    end

    it "should call the path proc with the next page when #next is called" do
      @path.should_receive(:call).with(@page.next)
      @paginator.next
    end
    
    it "should not call the path proc when #previous is called" do
      @path.should_not_receive(:call)
      @paginator.previous.should be_nil
    end
  end

  context "for any other page" do
    before(:each) do
      @page = @pages.all.second
      @paginator = @page.paginator
      @paginator.set_path(&@path)
    end

    it "should call the path proc with the next page when #next is called" do
      @path.should_receive(:call).with(@page.next)
      @paginator.next
    end
    
    it "should call the path proc with the previous page when #previous is called" do
      @path.should_receive(:call).with(@page.previous)
      @paginator.previous
    end
  end
  
  describe "window generator" do
    before(:each) do
      @args = []
    end
    
    it "should raise an error if no block is provided" do
      lambda { @pages.first.paginator.window({}) }.should raise_error(ArgumentError)
    end
    
    it "should concatenate all the block return values into a string" do
      page = @pages.find(6)
      page.paginator.set_path { |page| }
      links = (1..5).map { |n| "<li><a href='/path/to/page/#{n}'>1</a></li>" }
      links.join("\n").should == page.paginator.window(:size => 2) { |page, path| links.shift }
    end
    
    it "should call the block with the page and the path for each page in a window surrounding the page" do
      [ [ 6, 6-@size..6+@size ], [ 2, 1..2+@size ], [ 1, 1..1+@size ], [ @page_count-1, @page_count-1-@size..@page_count ], [ @page_count, @page_count-@size..@page_count ] ].each do |number, range|
        page = @pages.find(number)
        page.paginator.set_path(&@path)
        expected_args = []
        range.map { |nearby_number| @pages.find(nearby_number) }.each do |nearby_page|
          expected_args << [ nearby_page, @path.call(nearby_page) ]
        end
        page.paginator.window(:size => @size) do |*args|
          expected_args.shift.should == args
        end
        expected_args.should be_empty
      end
    end
    
    [ [ :previous, 2, 1 ], [ :next, 1, 2 ] ].each do |extra, number, new_number|
      it "should call the block with #{extra.inspect} and the path for the #{extra} page if #{extra.inspect} is specified as an extra" do
        page = @pages.find(number)
        page.paginator.set_path(&@path)
        page.paginator.window(:size => @size, :extras => [ extra ]) do |*args|
          @args << args
        end
        @args.should include([ extra, @path.call(@pages.find(new_number)) ])
      end
    end

    [ [ :previous, "1" ], [ :next, "@page_count" ] ].each do |extra, number|
      it "should call the block with #{extra.inspect} and a nil path if #{extra.inspect} is specified as an extra but there is no #{extra} page" do
        page = @pages.find(eval(number))
        page.paginator.set_path(&@path)
        page.paginator.window(:size => @size, :extras => [ extra ]) do |*args|
          @args << args
        end
        @args.should include([ extra, nil ])
      end
    end
    
    [ :first, :last ].each do |extra|
      it "should call the block with #{extra.inspect} and the path for the #{extra} page if #{extra.inspect} is specified as an extra" do
        page = @pages.find(6)
        page.paginator.set_path(&@path)
        page.paginator.window(:size => @size, :extras => [ extra ]) do |*args|
          @args << args
        end
        @args.should include([ extra, @path.call(@pages.send(extra)) ])
      end
    end

    [ [ :first, "1" ], [ :last, "@page_count" ] ].each do |extra, number|
      it "should call the block with #{extra.inspect} and a nil path if #{extra.inspect} is specified as an extra but the current page is the #{extra} page" do
        page = @pages.find(eval(number))
        page.paginator.set_path(&@path)
        page.paginator.window(:size => @size, :extras => [ extra ]) do |*args|
          @args << args
        end
        @args.should include([ extra, nil ])
      end
    end
    
    it "should call the block with :first, :previous, pages, :next, :last in that order" do
      page = @pages.find(6)
      page.paginator.set_path(&@path)
      pages_in_order = []
      page.paginator.window(:size => 1, :extras => [ :first, :previous, :next, :last ]) do |page, path|
        pages_in_order << page
      end
      pages_in_order.should == [ :first, :previous, @pages.find(5), @pages.find(6), @pages.find(7), :next, :last ]
    end
  end

end