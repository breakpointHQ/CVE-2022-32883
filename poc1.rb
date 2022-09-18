# Example Coordinates:
# 32.0668,34.7605226 - Kaufmann St 10, Tel Aviv-Yafo, Israel
# 37.3313664,-122.0336009 - 10627 Bandley Dr, Cupertino, CA 95014, United States

require_relative 'get_distance_from'

private

def main
    wifi_warning
    
    coordinates = ARGV[0]

    if !coordinates
        return log "ERROR: Coordinates were not provided.\ntry: ruby poc1.rb <latitude>,<longitude>", RED
    end

    if !coordinates.match /^[-+]?([1-8]?\d(\.\d+)?|90(\.0+)?),\s*[-+]?(180(\.0+)?|((1[0-7]\d)|([1-9]?\d))(\.\d+)?)$/i
        return log 'ERROR: Invalid latitude and longitude coordinates', RED
    end

    log "[+] Finding your distance from: #{coordinates}..."

    begin
        distance = get_distance_from coordinates
        log "SUCCESS: You are about #{distance/1000}km away.", GREEN
    rescue StandardError => err
        log "ERROR: #{err}", RED
    end

end

main