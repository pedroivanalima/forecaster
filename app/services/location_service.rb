class LocationService

    include LocationParserHelper

    SERVICE_URL = ENV["geocode_url"].freeze
    SERVICE_API_KEY = ENV["geocode_api_key"].freeze
    MAX_ATTEMPTS = 3

    def initialize
        @faraday = Faraday.new(url: SERVICE_URL) do |f|
            f.headers['Authorization'] = "Bearer #{SERVICE_API_KEY}"
        end
        @attempts = 0
    end

    def call(params)
        response = { cached: true }
        response[:locations] = Rails.cache.fetch(cache_key(params)) do
            response[:cached] = false
            Location.search_by_text(params[:q]).map(&:to_resp) 
        end
        
        case response[:locations].size
        when 0 # never searched before
            # create an empty location with the search to block new jobs being enqueued
            new_location = Location.create!(search: [params[:q]])
            LocationJob.new.perform(params.merge(new_location_id: new_location.id))
            response[:status] = 202
            cache_delete(params)
            # and calls for an update right away
            ForecastJob.new.perform(new_location.id) if new_location.valid_coordinates?
        when 1
            location = Location.new(response[:locations].first.slice(:latitude, :longitude))
            if location.invalid_coordinates? # no address was found with given search
                response[:status] = 404 
            elsif location.blank_coordinates? # job hasn't returned yet
                response[:status] = 202
                # reintroduces in cache with a timeout in order to avoid pooling, but searching again after a few seconds
                location = cache_delete(params)
                cache_add(params, location)
            else
                response[:status] = 200
            end
        else
            response[:status] = 200
        end

        response
    end

    def fetch(params)
        response_hash = { status: nil }
        until response_hash[:status] == 200 || (@attempts += 1) >= MAX_ATTEMPTS
            resp = @faraday.get("/search", { q: params[:q] }) 
            response_hash[:status] = resp.status

            case resp.status
            when 200
                locations = JSON.parse(resp.body)
                response_hash[:locations] = locations.collect {|l| parse_location(l) }
            when 429, 503 # 429 asks for a throttling and 503 is server buzy
                sleep @attempts 
            when 403 # help, panic
                Rails.logger.error "GeoCode BLOCKED US!"
                break
            end
        end

        response_hash
    end

    private

    def cache_key(params)
        "location-#{params[:q]}"
    end

    # job may be running anywhere, to avoid pooling we cache for some seconds before seeing if it was updated
    def cache_add(params, location)
        Rails.cache.write(cache_key(params), location, expires_in: 4.seconds) unless Rails.cache.read(cache_key(params))
    end

    def cache_delete(params)
        Rails.cache.delete(cache_key(params))
    end
end
