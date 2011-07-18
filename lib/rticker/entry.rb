
module RTicker

  ##############################
  # Parent class to represent all types of ticker entries to watch.  The
  # classes that subclass from Entry are: Equity, Currency, Future, and
  # Option.
  class Entry
    
    # @symbol represents the ticker symbol for an entry (e.g., AAPL, MSFT,
    # etc.)  @description is an optional string that can give a more
    # user-friendly description of a symbol.  If a description is not
    # provided, the symbol itself is displayed to the user.  If the user
    # provides information on having purchased an entry (for example AAPL
    # stock), the user may specify how many via @purchase_count (in this case
    # how many shares), and for how much via @purchase_price (in this case
    # how much paid per share).  A user can specify a negative
    # @purchase_count to represent a SHORT position.  @bold specifies if
    # this entry should stand apart from other entries when displayed to the
    # user.
    attr_accessor :symbol, :description, :purchase_count, :purchase_price
    attr_accessor :bold, :curr_value, :last_changed
    
    alias bold? bold
    
    def initialize (symbol, description=nil, purchase_count=nil, purchase_price=nil, bold=false)
      @symbol = symbol
      @description = description
      @purchase_count = purchase_count
      @purchase_price = purchase_price
      @bold = bold
      @last_changed = nil
    end
  end # class Entry

end # module
