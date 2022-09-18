require 'open-uri'
require 'maxminddb'
require_relative 'get_distance_from'

private

if !File.exist? 'db.mmdb'
    raise log "ERROR: db.mmdb file is required\n", RED
end

DB = MaxMindDB.new('db.mmdb')

def main
    wifi_warning
    start_at = Time.now.to_i
    
    begin
        # This uses Maxmind database to find an approximate location based on the device IP.
        approximate_location = approximate_location_by_ip
        
        best_coord = Coord.new approximate_location.latitude, approximate_location.longitude
        best_distance = get_distance_from best_coord.to_s

        # This is the distance we step in every direction, searching for the device location
        # This distance will be divided in half on every iteration.
        step = 0.1 + (best_distance/1000) / 4

        log "distance=#{best_distance/1000}km, coord=#{best_coord}, step=#{step}, accuracy_radius=#{approximate_location.accuracy_radius}km", YELLOW

        while true
            # Finds if we should be scanning right or left
            lng_direction = lng_find_direction best_coord, 0.5

            for i in 1...5
                print "🛰️ "
                km = (step * i) * lng_direction
                new_coord = best_coord.lng_add_km km
                new_distance = distance_from new_coord
                if new_distance == nil
                    break
                end
                if new_distance < best_distance
                    best_distance = new_distance
                    best_coord = new_coord
                    log "\n📍 NEW BEST: distance=#{best_distance/1000}km, coord=#{best_coord.to_s}", GREEN
                    if step > best_distance/1000
                        break
                    end
                end
            end

            print " "

            # Finds if we should be scanning top or bottom
            lat_direction = lat_find_direction best_coord, 0.5

            for i in 1...5
                print "🛰️ "
                km = (step * i) * lat_direction
                new_coord = best_coord.lat_add_km km
                new_distance = distance_from new_coord
                if new_distance == nil
                    break
                end
                if new_distance < best_distance
                    best_distance = new_distance
                    best_coord = new_coord
                    log "\n📍 NEW BEST: distance=#{best_distance/1000}km, coord=#{best_coord.to_s}", GREEN
                    if step > best_distance/1000
                        break
                    end
                end
            end

            step = [step / 2, (best_distance/1000) / 4].min

            if step <= 0.02 || step > best_distance/1000
                log "\nDONE, distance=#{best_distance/1000}km, coord=#{best_coord.to_s}", GREEN
                break
            end

            log "\nnext step size=#{step}, time=#{(Time.now.to_i-start_at)} seconds", YELLOW
    end

    rescue StandardError => err
        log "ERROR: #{err}", RED
    end
end

def lng_find_direction(coord, km)
    c1_distance = distance_from coord.lng_add_km(km).to_s
    c2_distance = distance_from coord.lng_add_km(km*-1).to_s

    if c1_distance == nil
        log "WARNING: distance_from failed, trying again with: #{km.to_f/2} [lng_find_direction]", YELLOW
        return lng_find_direction coord, km.to_f/2
    end

    if c2_distance == nil
        log "WARNING: distance_from failed, trying again with: #{km.to_f/2} [lng_find_direction]", YELLOW
        return lng_find_direction coord, km.to_f/2
    end

    if c2_distance < c1_distance
        return -1
    end
    
    return 1
end

def lat_find_direction(coord, km)
    c1_distance = distance_from coord.lat_add_km(km).to_s
    c2_distance = distance_from coord.lat_add_km(km*-1).to_s

    if c1_distance == nil
        log "WARNING: distance_from failed, trying again with: #{km.to_f/2} [lat_find_direction]", YELLOW
        return lat_find_direction coord, km.to_f/2
    end

    if c2_distance == nil
        log "WARNING: distance_from failed, trying again with: #{km.to_f/2} [lat_find_direction]", YELLOW
        return lat_find_direction coord, km.to_f/2
    end

    if c2_distance < c1_distance
        return -1
    end
    
    return 1
end

def distance_from(coord)
    begin
        return get_distance_from coord.to_s
    rescue StandardError => err
        return nil
    end
end

def approximate_location_by_ip
    ip = open('http://whatismyip.akamai.com').read
    log "IP: #{ip}", YELLOW
    result = DB.lookup(ip)

    if !result.found?
        raise StandardError.new 'Your IP was not found in the Maxmind database.'
    end

    return result.location
end

class Coord
    def initialize(lat, lng)
        @lat = lat
        @lng = lng
    end

    def lat_add_km(km)
        return Coord.new @lat+(0.01*km), @lng
    end

    def lng_add_km(km)
        return Coord.new @lat, @lng +(0.01*km)
    end

    def to_s
        return "#{@lat},#{@lng}"
    end
end

main