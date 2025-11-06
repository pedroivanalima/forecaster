class Forecast < ApplicationRecord
    
    belongs_to :location

    def need_update?
        (Time.now - self.updated_at) > 30.minutes
    end

    def to_resp
        { id: self.id, location_id: self.location_id }.merge self.data.deep_symbolize_keys
    end
end