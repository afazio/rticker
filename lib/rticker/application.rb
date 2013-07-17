
require 'rticker/options'
require 'rticker/parser'
require 'rticker/printer'
require 'rticker/tput'

module RTicker

  DEFAULT_ENTRY_FILE = "#{ENV['HOME']}/.rticker"

  class Application

    def initialize (args)
      # Parse recognizable options from command line.  Strips away recognizable
      # options from ARGV.
      @options = Options.new(args)
      @text_entries = []
      @entries = []
    end

    def run ()
      # text_entries is an array of ticker entries in raw text format.
      # Any left over arguments should be ticker entries.
      @text_entries = @options.rest

      @options.input_files.each do |file|
        # For each file passed via the CLI, read its entries into text_entries.
        @text_entries += RTicker::read_entry_file(file)
      end

      if @text_entries.empty?
        # If no entries were passed via CLI, then try to read from $HOME/.rticker
        @text_entries += RTicker::read_entry_file(DEFAULT_ENTRY_FILE)
      end

      if @text_entries.empty?
        # Still no entries?  Then there's nothing to do.
        puts "No ticker entries provided.  Exiting."
        exit
      end

      # Parse text_entries into instances of Equity, Future, Currency, Option,
      # and Separator
      @entries = @text_entries.map {|entry| RTicker::parse_entry(entry)}

      currency_entries = @entries.select {|e| e.instance_of? Currency }
      option_entries = @entries.select {|e| e.instance_of? Option }
      future_entries = @entries.select {|e| e.instance_of? Future }
      google_equity_entries = @entries.select {|e| e.instance_of? Equity and e.source == :google  }
      yahoo_equity_entries = @entries.select {|e| e.instance_of? Equity and e.source == :yahoo  }

      # Don't raise an exception when user hits Ctrl-C.  Just exit silently
      Signal.trap("INT") do
        # Show the cursor again and shutdown cleanly.
        print RTicker::tput "cnorm" unless @options.once?
        exit
      end

      # Set proxy settings
      system_proxy = RTicker::Net.detect_system_proxy
      if @options.proxy
        RTicker::Net.proxy = @options.proxy
      elsif not system_proxy.nil? and not @options.no_proxy
        RTicker::Net.proxy = "#{system_proxy[:host]}:#{system_proxy[:port]}"
      end

      # Update entries via web calls until user quits via Ctrl-C
      while true
        threads = []

        # Update each type of entry in its own thread.
        threads << Thread.new { Currency.update(currency_entries) }
        threads << Thread.new { Option.update(option_entries) }
        threads << Thread.new { Future.update(future_entries) }
        threads << Thread.new { Equity.update(google_equity_entries, :google) }
        threads << Thread.new { Equity.update(yahoo_equity_entries, :yahoo) }

        # Wait for them all to finish executing
        threads.each {|t| t.join}

        # Show updated info to the user
        RTicker::update_screen @entries, @options.no_color?, @options.once?

        # If the user only wanted us to grab this info and display it once,
        # then we've done our job and its time to quit.
        exit if @options.once?

        sleep @options.sleep
      end
    end

  end # class

end # module
