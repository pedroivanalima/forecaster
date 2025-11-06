class HomeController < ApplicationController
    before_action :initialize_variables

    include ApplicationHelper

    def index
        #Rails.logger.info "Home Controller Index INFO"
        log_info params.to_s
        if query[:q].present?
            from_cache = []
            @location = LocationService.new.call(query)
            search_location = query[:location_id] || @location[:locations]&.first&.dig("id")
            @forecast = ForecastService.new.call(search_location) if search_location.present?
            from_cache << "Got location from cache." if @location[:cached]
            from_cache << "Got forecast from cache." if @forecast[:cached]
            flash[:notice] = from_cache.join(" ") if from_cache.length > 0
        end
    rescue => e
        log_error(e.message + "\n" + e.backtrace[0..5].join("\n"))
        flash[:error] = "Issue processing your request"
    end

    private

    def initialize_variables
        @location = {}
        @forecast = {}
        @cached = true
    end

    def query
        params.permit(:q, :location_id)
    end
end