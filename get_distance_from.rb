require 'digest/md5'

DELAY = 0.2
HIDE_MAP = true

def get_distance_from(location, timeout = 6)
    close_maps

    distance = nil
    last_hash = nil
    file_path = tmp_file_path

    time_passed = 0
    search_in_maps location, file_path

    while true
        if time_passed >= timeout
            raise StandardError.new "Timeout error, Maps could not determine the driving distance to the provided coordinates.\nPlease make sure the Maps app is able to access your location, and that you have provided coordinates in your country."
        end

        sleep DELAY
        time_passed = time_passed + DELAY

        hash = md5_file file_path

        if hash != last_hash
            last_hash = hash
            distance = extract_distance_data file_path
            if distance != nil
                return distance
            end
        end
    end
end

RED = 31
GREEN = 32
YELLOW = 33

def log(message, color = nil)
    if color != nil
        message = "\e[#{color}m#{message}\e[0m"
    end
    puts message
end

def wifi_warning
    for i in (0...3)
        result = `networksetup -getairportpower en#{i}`
        if result.match /Wi-Fi.+Off/
            log "WARNING: the Maps app might not be able to find your current location when WiFi is off.", YELLOW, ""
        end
    end
end

private

def md5_file(file_path)
    if !File.exist? file_path
        return nil
    end

    fd = File.open(file_path, 'rb')
    hash = Digest::MD5.hexdigest(fd.read)
    fd.close

    return hash
end

def extract_distance_data(file_path)
    distance = nil
    content = File.read(file_path)
    lines = content.split("\n")
    
    for line in lines
        if line.include? "FAILED_NO_RESULT"
            raise StandardError.new 'Maps could not resolve the provided coordinates.'
        end
        if line.include? "AUTOMOBILE"
            matches = line.match(/distance = (\d+);/i)
            if matches != nil
                distance = matches.captures[0].to_f
            end
        end
    end

    return distance
end

def tmp_file_path
    return "/tmp/f_#{rand(1...99999999999)}"
end

def close_maps
    `pkill -a -i "Maps"`
    sleep 0.69
end

def search_in_maps(location, file_path)
    flags = HIDE_MAP ? '-j -g' : ''
    location = URI.escape location
    `open #{flags} --stderr #{file_path} -a maps \"http://maps.apple.com/?q=#{location}\"`
end