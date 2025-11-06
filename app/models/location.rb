class Location < ApplicationRecord

    has_one :forecast, dependent: :destroy

    scope :search_by_text, ->(query) {
        where("? = ANY(search) ", query)
    }

    scope :only_valids, -> {
        where("latitude is not null and latitude <> 99.99 and longitude is not null and longitude <> 999.99")
    }

    def to_resp
        self.slice(:id, :latitude, :longitude, :name, :display_name)
    end

    def invalid_coordinates?
        latitude == 99.99 && longitude == 999.99
    end

    def blank_coordinates?
        latitude.nil? && longitude.nil?
    end

    # there's no coordinates above 90 (nor below -90)
    def invalidate_coordinates
        self.update(latitude: 99.99, longitude: 999.99)
    end

    def valid_coordinates?
        !blank_coordinates? && !invalid_coordinates?
    end
end