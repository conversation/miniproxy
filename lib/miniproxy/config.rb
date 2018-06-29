module MiniProxy
  # MiniProxy-level configuration options
  #
  class Config < Struct.new(:allow_external_requests)
  end
end
