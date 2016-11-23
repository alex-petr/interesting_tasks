module ParserSupport
  module URIHandler
    # Check is URI valid.
    def uri_valid?(uri)
      !!URI.parse(uri)
    rescue URI::InvalidURIError
      false
    end

    # Encode URI if it's invalid.
    def uri_encode(uri)
      uri_valid?(uri) ? uri : URI.encode(uri).gsub('[', '%5B').gsub(']', '%5D')
    end
  end
end
