require 'rticker/tput'
require 'rticker/types'

module RTicker

  ##############################
  # Update the screen with the latest information.
  def RTicker.update_screen (entries, no_color=false, once=false)
    # An interesting side-effect of using unless here is that if no_color is
    # true, then all of these variables are still created, but set to nil.
    # So setting no_color effectively turns all of the following variables
    # into empty strings, turning off terminal manipulation.
    hide_cursor = tput "civis" unless no_color
    #show_cursor = tput "cnorm" unless no_color
    bold = tput "bold" unless no_color
    unbold = tput "sgr0" unless no_color
    default = tput "sgr0" unless no_color
    red = tput "setaf 1" unless no_color
    green = tput "setaf 2" unless no_color
    blue = tput "setaf 4" unless no_color

    if not once
      print %x[clear]
      print "#{hide_cursor}"
    end
    print "#{default}"
    
    # Calculate the longest symbol name or description
    max_length = 0
    for entry in entries.select {|e| not e.is_a? Separator}
      output = entry.description || entry.symbol
      max_length = [output.size, max_length].max
    end
    max_length += 2 # Give a little extra breathing room

    for entry in entries
      if entry.is_a? Separator
        print "___________________________________________\n"
        next # Skip to the next entry
      end

      # Prefer a description over a raw symbol name.  Use max_length to left
      # align the output with extra padding on the right.  This lines
      # everything up nice and neat.
      output = "%-#{max_length}s" % (entry.description || entry.symbol)
      output = "#{bold}#{output}#{unbold}" if entry.bold?

      # If we're still waiting for valid responses from yahoo or google, then
      # just let the user know that they need to wait.
      curr_value = entry.curr_value || "please wait..."

      if entry.is_a? Option
        curr_value = "#{entry.bid}/#{entry.ask}" if entry.bid
      end

      # Does this entry have a start_value?  If so, let's calculate the
      # change in percent.
      change_string = nil
      if entry.respond_to? :start_value and not entry.start_value.nil?
        change = entry.curr_value - entry.start_value
        change_percent = (change / entry.start_value) * 100
        color = (change >= 0 ? "#{green}" : "#{red}")
        change_string = " (#{color}%+.2f %%%0.2f#{default})" % [change, change_percent]
      end

      # If this entry has purchase info, let's calculate profit/loss
      profit_string = nil
      if entry.purchase_count != 0 and not entry.curr_value.nil?
        count = entry.purchase_count
        price = entry.purchase_price
        # Options are purchased in multiples of 100 of the contract price
        count *= 100 if entry.is_a? Option 
        # There is also a price multiplier for futures, but they are
        # completely different for each contract.  So the user will simply
        # need to enter the correct multiplier when configuring the
        # purchase_count in the ticker entry.  For instance, a contract for
        # CL, crude light sweet oil, has a multiplier of 1000.  Ie, one
        # contract represents 1000 barrels of oil.  So if a contract is
        # bought, the user should enter a purchase_count of 1000.  If the
        # contract is sold (a short position), the purchase_count should be
        # -1000.
        profit_loss = count * entry.curr_value - count * price
        profit_loss_percent = profit_loss / (count*price) * 100
        color = (profit_loss >= 0 ? "#{green}" : "#{red}")
        profit_string = " = #{color}$%.2f %%%0.2f#{default}" % [profit_loss, profit_loss_percent]
      end

      case entry
      when Equity
        print "#{output} #{curr_value}#{change_string}#{profit_string}"
      when Future
        print "#{output} #{curr_value}#{change_string}#{profit_string}"
      when Option
        print "#{output} #{curr_value}#{profit_string}"
      when Currency
        print "#{output} #{curr_value}#{profit_string}"
      end

      # Let the user know with a blue asterisk if this entry has changed
      # within the past 5 minutes.
      if entry.last_changed and (Time.now() - entry.last_changed) <= 5*60
        print " #{blue}*#{default}"
      end

      print "\n"
    end # for
    
  end # def

end
