class ForecastJob < ApplicationJob
    
    include ApplicationHelper

    def perform(location_id)
        log_info "#{self.class.name}(#{location_id}) at #{Time.current}"
        location = Location.find(location_id)
        response = ForecastService.new.fetch(location)
        forecast = location.forecast || Forecast.new(location_id: location_id)
        forecast.update(data: response.slice(:forecast, :current))
    end
end