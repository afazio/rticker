require 'optparse'  # Use OptionParser to parse command line args

module RTicker

  class Options

    attr_reader :once, :no_color, :input_files
    attr_reader :sleep, :rest, :proxy, :no_proxy
    
    def initialize (args)
      # Defaults
      @once = false     # Only run once then quit
      @no_color = false # Don't use color when showing results to user
      @input_files = [] # Input files provided by user
      @proxy = nil      # "host:port" proxy
      @no_proxy = false # Don't default to system proxy if one is detected
      @sleep = 2        # how long to delay between web requests
      @rest = []        # The rest of the command line arguments
      parse!(args)
    end

    alias no_color? no_color
    alias once? once

    private

    def parse! (args)
      # Use OptionParser to parse command line arguments
      OptionParser.new do |opts|
        opts.banner = "Usage: rticker [-onh] [-d SECS] [-p host:port] [-f FILE] ... [SYMBOL[,DESC[,COUNT@PRICE]]] ..."
        
        opts.on("-o", "--once", "Only display ticker results once then quit") do
          @once = true
        end
        
        opts.on("-n", "--no-color", "Do not use colors when displaying results") do
          @no_color = true
        end
        
        opts.on("-f", "--file FILE", "Specify a file that lists ticker entries, one per line") do |file|
          @input_files << file
        end

        opts.on("-d", "--delay SECS", "How long to delay in SECS between each update") do |secs|
          @sleep = secs.to_f
        end
        
        opts.on("-p", "--proxy HOST:PORT", "Host and port of HTTP proxy to use.  This overrides any system proxy that is detected.") do |proxy|
          @proxy = proxy
        end
        
        opts.on("-x", "--no-proxy", "Don't default to system proxy if one is detected.") do
          @no_proxy = true
        end
        
        opts.on("-h", "--help", "Display this screen") do 
          puts opts
          exit
        end

        # Parse options and pop recognized options out of ARGV.
        # If a parse error occurs, print help and exit
        begin
          opts.parse!(args)
        rescue OptionParser::ParseError => e
          STDERR.puts e.message, "\n", opts 
          exit(-1)
        end
        @rest = args
      end
    end

  end # class

end # module
