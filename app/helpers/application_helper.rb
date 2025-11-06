module ApplicationHelper
    def log_info(log_string)
        Rails.logger.info log_message(log_string)
    end

    def log_error(log_string)
        Rails.logger.error log_message(log_string)
                          
    end

    def log_header
        "\n#{self.class.name} at #{Time.current.to_s}"
    end

    def log_message(log_string)
        "\n" + "-" * 60 + log_header + "\n#{log_string}\n\n\n"
    end
end
