module ForecastParamsHelper
    DEFAULT_PARAMS = {
        daily: [
            "temperature_2m_min",
            "temperature_2m_max",
            "rain_sum"
        ],
        current: [
            "temperature_2m"
        ],
        timezone: "auto"        
    }.freeze

    def build_params(location)
        DEFAULT_PARAMS.merge(latitude: location[:latitude], longitude: location[:longitude])
    end
end