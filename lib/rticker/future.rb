require 'rticker/entry'
require 'rticker/net'
require 'cgi'

module RTicker

  ##############################
  # Represents futures contracts (e.g., oil, gold, corn, wheat)
  class Future < Entry
    # Futures contracts expire on a given month and year.  Let's track that
    # information to display to the user.  Might as well show the @market
    # that the contract is traded on, too.  For instance oil can be traded via
    # NYMEX or ICE (InterContinental Exchange).  Also, because we won't know
    # ahead of time what the nearest expiration for a contract will be, we'll
    # have to figure this out for each contract with web calls.  Once we know
    # the expiration, we'll calculate the real symbol for the contract and
    # store it in @real_symbol.
    attr_accessor :start_value, :exp_month, :exp_year, :market
    attr_accessor :real_symbol

    # Commodities have strange codes for months
    COMMODITY_MONTHS = %w[F G H J K M N Q U V X Z]

    def initialize (symbol, description=nil, purchase_count=nil, purchase_price=nil, bold=false)
      super(symbol, description, purchase_count, purchase_price, bold)
      @start_value=nil
      @exp_month=nil
      @exp_year=nil
      @market=nil
      @real_symbol=nil
    end

    def Future.update (entries)
      # Futures are special.  The first run requires us to find the spot
      # contract for the commodity in question.  The spot contract is simply
      # the closest expiring contract that is still open for trades.
      # Determining the spot contract is not always clear, and so we must
      # brute force to find the answer.  When we find the spot contract, we
      # set the entry's real_symbol attribute to the actual spot contract's
      # symbol.  Got it?

      # Since variables are shared in block closures, a simple for loop
      # won't do.  We must create a new Proc to eliminate sharing of the
      # entry variable.
      go = Proc.new do |entry|
        Thread.new { entry.determine_spot_contract }
      end

      if entries.any? {|e| e.real_symbol.nil?}
        #puts "Please wait... determining spot contracts"
        threads = []
        for entry in entries
          if not entry.real_symbol
            threads << go.call(entry)
          end
        end
        threads.each {|t| t.join}
      end

      # All spot contracts have been found.  Now let's update our entries
      # with the latest price information.  This is what we came here for!
      symbols = entries.map { |e| e.real_symbol }
      uri = "http://download.finance.yahoo.com/d/quotes.csv?s=%s&f=l1c1d1va2xj1b4j4dyekjm3m4rr5p5p6s7" % CGI.escape(symbols.join(","))
      response = RTicker::Net.get_response(uri) rescue return
      return if response.empty?
      results = response.split("\n")
      entries.zip(results) do |_entry, result|
        # Yahoo uses A CSV format.
        fields = result.split(",")
        return if fields[4] == '""' # This is a sign yahoo is giving us bad info
        price  = fields[0]
        change = fields[1]
        last_date = fields[2]
        return if Date.strptime(last_date, '"%m/%d/%Y"') != Date.today
        if price.to_f != _entry.curr_value and not _entry.curr_value.nil?
          # The price has changed
          _entry.last_changed = Time.now() 
        end
        _entry.curr_value  = price.to_f
        _entry.start_value = _entry.curr_value - change.to_f
      end
    end # def

    def determine_spot_contract
      # This is as nasty as it gets.  Keep trying contracts, month after
      # month, until we find a valid one.  Stop after 9 failed attempts.
      attempt_count = 9 # Maximum number of attempts to try

      symbol, exchange = @symbol.split(".")
      @market = exchange
      curr_month = curr_year = nil
      
      while attempt_count > 0
        if curr_month.nil?
          # By default start looking at next month.  Also, let's use a zero
          # based index into months.  Jan == 0, Dec == 11
          curr_month = Time.now().month % 12
          curr_year  = Time.now().year
        else
          curr_month = (curr_month + 1) % 12
        end
        curr_year += 1 if curr_month == 0  # We've rolled into next year
        month_symbol = Future::COMMODITY_MONTHS[curr_month]
        year_symbol = curr_year % 100 # Only want last two digits of year.
        real_symbol_attempt = "#{symbol}#{month_symbol}#{year_symbol}.#{exchange}"
        uri = "http://download.finance.yahoo.com/d/quotes.csv?s=%s&f=l1c1va2xj1b4j4dyekjm3m4rr5p5p6s7" % CGI::escape(real_symbol_attempt)
        response = RTicker::Net.get_response(uri) rescue return

        # This contract is only valid if the response doesn't start with
        # 0.00.  A commodity is never worth nothing!
        unless response =~ /^0.00/
          @real_symbol = real_symbol_attempt
          @exp_month = curr_month+1 # Convert from 0-based back to 1-based
          @exp_year = curr_year
          break # Get out of this loop!
        end
        attempt_count -= 1
      end # while

      if attempt_count == 0 and @real_symbol.nil?
        # Can't determine month for this contract.  Set the real_symbol to
        # symbol and hope for the best.
        @real_symbol = @symbol
      end
    end # def

  end # class Future

end # module
