require 'rticker/types'
require 'pathname'

module RTicker
  
  ##############################
  # Read raw text entries, line by line, from file.  Return result as an
  # array of text entries.  File "-" represents STDIN.
  def RTicker.read_entry_file (file, context=nil)
    context ||= Dir.pwd

    # If this is a relative path, make it absolute according to context
    if file != "-" and file[0,1] != "/"
      file = [context, file].join("/")
    end

    # If we're not dealing with a readable source then get out of here
    return [] if file != "-" and not File.readable? file

    if File.symlink? file
      # Follow symlinks so that we can honor relative include directives
      return read_entry_file(Pathname.new(file).realpath.to_s)
    end
    
    entries = []
    source = if file == "-" then $stdin else File.open(file) end
    source.each do |line|
      line.chomp!
      case line
      when  /^;/, /^\s*$/
        # If this line starts with a semicolon (comment) or only contains
        # whitespace, ignore it.
        next
      when /^@.+/
        # If this line starts with an @ sign, then this is an 'include'
        # directive.  Ie, this entry is simply including another entry file.
        # Eg: @otherfile.txt
        # This will include another file called otherfile.txt
        include_file = line[1..-1]
        context = File.dirname(file) unless file == "-"
        entries += read_entry_file(include_file, context)
      else
        entries << line
      end
    end
    
    entries
  end # read_entry_file

  ##############################
  # Parse a raw text entry into an instance of Equity, Future, Currency,
  # Option, or Separator.
  def RTicker.parse_entry (entry)

    # An entry starting with a dash represents a Separator
    return Separator.new if entry[0,1] == "-"

    # An entry beginning with an asterisk represents a bold entry.
    bold = false
    if entry[0,1] == "*"
      bold = true
      entry = entry[1..-1] # Shift off asterisk
    end
    
    ## Here is a breakdown of the format: 
    ## [sign]symbol[,desc[,purchase_count@purchase_price]]
    ## Where sign can be a "#" (Future), "!" (Option), "^" (Yahoo Equity), 
    ## or "$" (Currency).  Anything else represents a Google Equity.
    pattern = /^([#!^$])?([^,]+)(?:,([^,]*)(?:,(-?[0-9]+)@([0-9]+\.?[0-9]*))?)?/
    match = pattern.match entry

    sign = match[1]
    symbol = match[2]

    if sign == '#' # This is a future
      submatch = /(.*)\+([0-9]+)$/.match symbol
      if submatch
        symbol = submatch[1]
        forward_months = submatch[2].to_i
      end
    end

    # Because description is optional, let's make it clear with a nil that no
    # description was provided.
    description = match[3] == "" ? nil : match[3]
    purchase_count = match[4]
    purchase_price = match[5]

    args = [symbol, description, purchase_count.to_f, purchase_price.to_f, bold]
    case sign
    when "#"
      # An entry starting with a hash is a Future.  A useful mnemonic is to
      # think of the "pound" sign and think of lbs of a commodity.
      f = Future.new(*args)
      f.forward_months = forward_months
      return f
    when "!"
      # An entry starting with an exclamation mark is an option contract.
      return Option.new(*args)
    when "^"
      # An entry starting with a caret represents an equity to be fetched
      # from Yahoo Finance.
      e = Equity.new(*args)
      e.source = :yahoo
      return e
    when "$"
      # An entry starting with a dollar sign represents a currency pair.
      return Currency.new(*args)
    else
      # Everthing else is an equity to be fetched from Google Finance (the
      # default).
      return Equity.new(*args)
    end
  end
  
end # module
