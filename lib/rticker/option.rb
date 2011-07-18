require 'rticker/entry'
require 'net/http'
require 'uri'

module RTicker

  ##############################
  # Represents option contracts which are derivatives of either equities,
  # indexes or futures.
  class Option < Entry
    # Because option contracts are not traded as much as their underlying,
    # the bid/ask spread can be pretty high and there might be quite a bit of
    # time since a trade has occurred for a given contract.  Therefore it is
    # sometimes more meaningful to represent the value of an option by
    # showing both the current bid and ask prices rather than the last trade
    # price.
    attr_accessor :bid, :ask

    def initialize (symbol, description=nil, purchase_count=nil, purchase_price=nil, bold=false)
      super(symbol, description, purchase_count, purchase_price, bold)
      @bid = @ask = nil
    end

    def Option.update (entries)
      threads = []
      for entry in entries
        # Can only grab one option contract at a time, so request each one in
        # a separate thread.
        threads << Thread.new do
          uri = "http://finance.yahoo.com/q?s=%s" % entry.symbol
          response = Net::HTTP.get(URI.parse(URI.escape uri)) rescue break
          # Rake through the HTML and find the bits we want.
          # This can be a bit messy.
          begin
            bid_ask_line = response.grep(/Bid/)[0]
            bid = bid_ask_line.split("yfs_b00_")[1].split(">")[1].split("<")[0]
            ask = bid_ask_line.split("yfs_a00_")[1].split(">")[1].split("<")[0]
          rescue
            # These results aren't available from about 9am to 9:30am.
            # Yahoo's results are often 20-30 minutes behind.
            break
          end
          if (bid.to_f != entry.bid or ask.to_f != entry.ask) and not entry.bid.nil?
            # The price has changed
            entry.last_changed = Time.now() 
          end
          entry.bid = bid.to_f
          entry.ask = ask.to_f
          # The value is the mean average of the bid/ask spread
          entry.curr_value = (entry.bid + entry.ask) / 2
        end
      end
      threads.each {|t| t.join}
    end
  end

end # module