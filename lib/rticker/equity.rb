require 'rticker/entry'
require 'net/http'
require 'uri'

module RTicker

  ##############################
  # Represents stocks/equities (e.g. AAPL, MSFT)
  class Equity < Entry
    # Equities can be retrieved via either Google Finance or Yahoo Finance.
    # @source should be set to one of either :google (the default) or :yahoo.
    # @start_value represents the value of the equity at market open.
    
    attr_accessor :start_value, :source

    def initialize (symbol, description=nil, purchase_count=nil, purchase_price=nil, bold=false)
      super(symbol, description, purchase_count, purchase_price, bold)
      @start_value=nil
      @source=:google
    end

    def Equity.update (entries, source=:google)
      if source == :google
        Equity.update_google(entries)
      elsif source == :yahoo
        Equity.update_yahoo(entries)
      else
        raise ArgumentError, "Unexpected symbol: #{source.to_s}"
      end
    end

    def Equity.update_google (entries)
      symbols = entries.map { |e| e.symbol }
      uri = "http://www.google.com/finance/info?client=ig&q=%s" % symbols.join(",")
      response = Net::HTTP.get(URI.parse(URI.escape uri)) rescue return
      return if response =~ /illegal/ # Google didn't like our request.
      results = response.split("{")[1..-1]
      entries.zip(results) do |entry, result|
        # Fish out the info we want.  Could use a JSON library, but that's
        # one more gem that would be required of the user to install.  Opted
        # instead for just two lines of super ugly code.
        price  = result.grep(/"l"/)[0].chomp.split(":")[-1].split('"')[-1].tr(',', '')
        change = result.grep(/"c"/)[0].chomp.split(":")[-1].split('"')[-1].tr(',', '')
        if price.to_f != entry.curr_value and not entry.curr_value.nil?
          # The price has changed
          entry.last_changed = Time.now() 
        end
        entry.curr_value  = price.to_f
        entry.start_value = entry.curr_value - change.to_f
      end
    end

    def Equity.update_yahoo (entries)
      symbols = entries.map { |e| e.symbol }
      uri = "http://download.finance.yahoo.com/d/quotes.csv?s=%s&f=l1c1va2xj1b4j4dyekjm3m4rr5p5p6s7" % symbols.join(",")
      response = Net::HTTP.get(URI.parse(URI.escape uri)) rescue return
      #return if response =~ /=/ # This is a sign yahoo is giving us bad info
      results = response.split("\n")
      entries.zip(results) do |entry, result|
        # Yahoo uses A CSV format.
        fields = result.split(",")
        price  = fields[0]
        change = fields[1]
        if price.to_f != entry.curr_value and not entry.curr_value.nil?
          # The price has changed
          entry.last_changed = Time.now() 
        end
        entry.curr_value  = price.to_f
        entry.start_value = entry.curr_value - change.to_f
      end
    end
  end # class Equity

end # module
