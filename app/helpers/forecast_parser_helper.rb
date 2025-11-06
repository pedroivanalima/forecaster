module ForecastParserHelper
    def parse_forecast(forecast)
        forecast.deep_symbolize_keys!
        @parsed_response = forecast.slice(:latitude, :longitude, :timezone_abbreviation)
        @parsed_response[:forecast] = {}
        @parsed_response[:current] = {}
        
        process_current forecast[:current]
        process_daily forecast[:daily]
        @parsed_response
    end

    def process_days(hourly_time)
        days = hourly_time.map {|h| h.split("T").first }.uniq
        days.each do |day|
            @parsed_response[:forecast][day] = {}
        end
    end 

    def process_current(current)
        @parsed_response[:current][:temperature] = current[:temperature_2m]
    end

    def process_daily(daily_data)
        days = daily_data[:time]
        days.each_with_index do |day, i|
            @parsed_response[:forecast][day] = {
                min_temperature: daily_data[:temperature_2m_min][i],
                max_temperature: daily_data[:temperature_2m_max][i],
                rain_sum: daily_data[:rain_sum][i],
            }
        end
    end
end