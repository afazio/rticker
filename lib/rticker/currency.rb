require 'rticker/entry'
require 'rticker/net'
require 'cgi'

module RTicker

  ##############################
  # Represents currency pairs (e.g. USD/EUR)
  class Currency < Entry
    # In the context of currency pairs, each increment in @purchase_count
    # represents single units of the quote currency exchanged for the base
    # currency.  (The base currency is the first of the pair, the quote
    # currency is the second.)  @purchase_price represents the pair ratio
    # when the purchase was made.  For instance, a @purchase_count of 1000
    # and @purchase_price of 1.412 for the currency pair 'EUR/USD' means that
    # $1000 USD was swapped for 708.21 euros.  A *negative* @purchase_count
    # of -1000 would mean that 1000 euros were swapped for $1,412 USD.

    def Currency.update (entries)
      # Strip out anything from symbol that is not an uppercase character
      # This allows the user to freely use USD/EUR or USD.EUR, etc.
      symbols = entries.map { |e| e.symbol.tr("^A-Z", "") }
      uri_param = symbols.map{|x| x+"=X"}.join(",")
      uri = "http://download.finance.yahoo.com/d/quotes.csv?s=%s&f=sl1d1t1ba&e=.csv" % CGI::escape(uri_param)
      response = RTicker::Net.get_response(uri) rescue return
      return if response.empty? or response =~ /"N\/A"/ # Yahoo sometimes returns bogus info.
      results = response.split("\n")
      entries.zip(results) do |entry, result|
        # Yahoo uses A CSV format.
        fields = result.split(",")
        price = fields[1]
        last_date = fields[2]
        return if Date.strptime(last_date, '"%m/%d/%Y"') != Date.today
        if price.to_f != entry.curr_value and not entry.curr_value.nil?
          # The price has changed
          entry.last_changed = Time.now() 
        end
        entry.curr_value = price.to_f
        # Currencies aren't regulated.  So no need to calculate the
        # @start_value, because there is no market open.  Currencies trade
        # 24/7
      end
    end
  end # class Currency

end # module
