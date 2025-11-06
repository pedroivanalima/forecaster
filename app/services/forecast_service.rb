class ForecastService

    include ForecastParamsHelper
    include ForecastParserHelper

    SERVICE_URL = ENV["open_meteo_url"].freeze
    MAX_ATTEMPTS = 3

    def initialize
        @faraday = Faraday.new(url: SERVICE_URL)
        @attempts = 0
    end

    # returns the latest forecast if available and may trigger an update if needed
    # requester may receive an old version of it while it is being processed, needing to request again
    def call(location_id)
        response = Rails.cache.read(cache_key(location_id))
        return response unless response.nil?

        response = { status: 200, cached: false }
        location = Location.find(location_id)
        forecast = location.forecast
        response.merge! forecast.to_resp if forecast
        # do we have forecast and is it up to date?
        if forecast&.need_update? == false
            cache_add(response.merge(cached: true), forecast)
        else
            # ok, call the job to update it, 205 reset content or 202 accepted ("creating")
            response[:status] = forecast.nil? ? 202 : 205
            ForecastJob.new.perform(location_id)
        end

        response
    end

    def fetch(location)
        response_hash = { status: nil }
        until response_hash[:status] == 200 || (@attempts += 1) >= MAX_ATTEMPTS
            begin
                resp = @faraday.get("/v1/forecast", build_params(location))
            rescue => e
                response_hash[:status] = 400
                binding.pry
            end
            response_hash[:status] = resp.status
            resp_body = JSON.parse(resp.body)

            case resp.status
            when 200
                response_hash.merge!(parse_forecast(resp_body))
            when 400, 404
                Rails.logger.error "Failed to get forecast: #{resp_body["reason"]}"
                break
            end
        end
        response_hash
    end

    def cache_key(location_id)
        "forecast-#{location_id}"
    end

    def cache_add(forecast_hash, forecast)
        # cache expires when has been 30 minutes since updated
        Rails.cache.write(cache_key(forecast.location_id), forecast_hash, expires_in: 30 - ((Time.now - forecast.updated_at)/60).floor)
    end

    def cache_delete(forecast)
        Rails.cache.delete(cache_key(forecast.location_id))
    end
end