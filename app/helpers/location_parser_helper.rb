module LocationParserHelper
    def parse_location(location)
        location.slice("name", "lat", "lon", "display_name").merge location["address"].slice("country", "postcode").deep_symbolize_keys
    end
end