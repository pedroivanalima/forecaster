class LocationJob < ApplicationJob

    include ApplicationHelper

    def perform(params)
        log_info params.to_s
        new_location = Location.find(params[:new_location_id])
        response = location_service(params).fetch(params)
        
        case response[:status]
        when 200
            if response[:locations].size > 0
                new_location.destroy
            else
                new_location.invalidate_coordinates
            end
        when 403, 429, 503
            new_location.invalidate_coordinates
        end

        if response[:status] == 200
            response[:locations].each do |l|
                location = Location.find_or_create_by({
                    latitude: l["lat"],
                    longitude: l["lon"],
                })
                # if location was already found through other means or is an approximation we keep the original name
                location.name = l["name"] if location.name.nil?
                location.display_name = l["display_name"] if location.display_name.nil?
                # but we update the search so it can be hit later
                location.search << params[:q]
                location.search << l[:postcode]
                location.search.uniq!
                location.save
            end
        end
    end

    def location_service(params)
        LocationService.new
    end
end