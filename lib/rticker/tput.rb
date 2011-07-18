module RTicker

  ##############################
  # tput is a command line utility used for sending special terminal codes.
  # This method is memoized to cut down on execution time.
  $__tput_cache = {}
  def RTicker.tput (args)
    if $__tput_cache.has_key? args
      $__tput_cache[args]
    else
      $__tput_cache[args] = %x[tput #{args}]
    end
  end

end
