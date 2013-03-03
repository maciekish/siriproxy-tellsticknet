require 'cora'
require 'siri_objects'
require 'pp'

#######
# Copyright (C) 2012 Maciej Swic
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation
# files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy,
# modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software
# is furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
# OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
# IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
######

class String

  def remove_lines(i)
    split("\n")[i..-1].join("\n")
  end

end

class SiriProxy::Plugin::Tellsticknet < SiriProxy::Plugin
  def initialize(config)
    #if you have custom configuration options, process them here!
  end

  #get the user's location and display it in the logs
  #filters are still in their early stages. Their interface may be modified
  filter "SetRequestOrigin", direction: :from_iphone do |object|
    puts "[Info - User Location] lat: #{object["properties"]["latitude"]}, long: #{object["properties"]["longitude"]}"

    #Note about returns from filters:
    # - Return false to stop the object from being forwarded
    # - Return a Hash to substitute or update the object
    # - Return nil (or anything not a Hash or false) to have the object forwarded (along with any
    #    modifications made to it)
  end

  #Returns a hash of lights
  def get_lights (*args)
    #Get string
    str_lights = `tdtool.py -l`
    str_lights = str_lights.remove_lines(1)

    lights = Hash.new()

    str_lights.each_line {|s| lights[s.match(/([0-9]{1,6})\s(.*)\s(OFF|ON|DIMMED)/)[2]] = s.match(/([0-9]{1,6})\s(.*)\s(OFF|ON|DIMMED)/)[1]}
    
    return lights
  end

  def get_lights_status (*args)
    str_lights = `tdtool.py -l`
    str_lights = str_lights.remove_lines(1)

    lights = Hash.new()

    str_lights.each_line {|s| lights[s.match(/([0-9]{1,6})\s(.*)\s(OFF|ON|DIMMED)/)[1]] = s.match(/([0-9]{1,6})\s(.*)\s(OFF|ON|DIMMED)/)[3]}

    return lights
  end

  #Returns a speakable string of lights
  def get_lights_speakable (*args)
    return get_lights.keys.join(', ')
  end

  #Finds a light ID based on name
  def get_light (light_name_needle)
    light = nil
    lights = get_lights

    print "Looking for '" + light_name_needle + "'\n"

    for key in lights.keys.sort
      #if "#{key.inspect}".downcase.include? light_name_needle.downcase
      if "#{key.inspect}".downcase.gsub("\"", "") == light_name_needle.downcase
        return "#{lights[key].inspect}"
      else
        #if "#{key.inspect}".gsub("\"", "").length > 2 and "#{key.inspect}".downcase.include? light_name_needle.downcase
        #  return "#{lights[key].inspect}"
        #end
      end
    end

    return light
  end

  def has_light (light_name)
    light = get_light(light_name.strip)

    if (light_id.nil?)
      return false
    else
      return true
    end
  end

  def has_light_spoken (light_name)
    light_id = get_light(light_name.strip)

    if (light_id.nil?)
      if (rand(200) > 50)
        say "You don't have a " + light_name.strip + " light. Maybe you don't have a " + light_name.strip + "? I don't judge.", spoken: "You don't have a " + light_name.strip + " light. . Maybe you don't have a " + light_name.strip + "? . . . I don't judge."
      else
        say "You don't have a " + light_name.strip + " light."
      end
      return false
    else
      print "Found light: " + light_id + "\n"
      return true
    end
  end

  def get_light_status (light_id)
    lights = get_lights_status

    if (!light_id.nil?)
      print "Looking for '" + light_id + "'\n"

      for key in lights.keys.sort
        if "#{key.inspect}" == light_id
          return "#{lights[key].inspect}".gsub("\"", "").downcase
        end
      end
    end

    return nil
  end

  def turn_on (light_id)
    cmd = "tdtool.py -n" + light_id
    result = `#{cmd}`

    if result.include? "success"
      return true
    else
      return false
    end

    return result
  end

  def turn_off (light_id)
    cmd = "tdtool.py -f" + light_id
    result = `#{cmd}`

    if result.include? "success"
      return true
    else
      return false
    end

    return result
  end

  def dim (light_id, level)
    cmd = "tdtool.py -v " + level.to_i.to_s + " -d " + light_id
    result = `#{cmd}`

    print "Setting " + light_id + " to " + level.to_s + ".\n"

    if result.include? "success"
      return true
    else
      return false
    end

    return result
  end

  listen_for /^(?:is|are)(?: the)? (.*?)light{0,1}s{0,1} (on|off|dimmed)/i do |light_name|
    result = has_light_spoken(light_name)
    unless result
      request_completed
    end

    light_name = light_name.strip
    light_id = get_light(light_name)
    light_status = get_light_status(light_id)

    if (light_id.nil?)
      say "You dont have a " + light_name + " light."
    else
      if (light_status.nil?)
        say "Sorry, I couldn't get the status for the " + light_name + " light."
      else
        say "The " + light_name + " light is " + light_status + "."
      end
    end
    
    request_completed
  end

  #todo: remove both duplicate on/off methods by improving the regex
  listen_for /turn(?: the)? (.*?)(light|lights){1} on/i do |light_name|
    result = has_light_spoken(light_name)
    unless result
      request_completed
    end

    light_name = light_name.strip
    light_id = get_light(light_name)

    if (!light_id.nil? and turn_on(light_id))
      if (rand(100) > 50)
        say "The " + light_name + " light you say. Let there be light.", spoken: "The " + light_name + " light, you say. . . Let there be light."
      else
        say "I have turned on the " + light_name + " light for you. Enjoy"
      end
    else
      say result
    end
    
    request_completed
      
  end

  #todo: remove both duplicate on/off methods by improving the regex
  listen_for /turn(?: the)? (.*?)(light|lights){1} off/i do |light_name|
    result = has_light_spoken(light_name)
    unless result
      request_completed
    end

    light_name = light_name.strip
    light_id = get_light(light_name)

    if (!light_id.nil? and turn_off(light_id))
      if (rand(100) > 90)
        say "I have turned the " + light_name + " light off. Welcome to the dark side."
      else
        say "I have turned the " + light_name + " light off."
      end
    else
      say result
    end
    
    request_completed
  end

  #todo: remove both duplicate on/off methods by improving the regex
  listen_for /turn on(?: the)? (.*?)(light|lights){1}/i do |light_name|
    result = has_light_spoken(light_name)
    unless result
      request_completed
    end

    light_name = light_name.strip
    light_id = get_light(light_name)

    if (!light_id.nil? and turn_on(light_id))
      if (rand(100) > 50)
        say "The " + light_name + " light you say. Let there be light.", spoken: "The " + light_name + " light, you say. . Let there be light."
      else
        say "I have turned on the " + light_name + " light for you. Enjoy"
      end
    else
      say result
    end
    
    request_completed
      
  end

  #todo: remove both duplicate on/off methods by improving the regex
  listen_for /turn off(?: the)? (.*?)(light|lights){1}/i do |light_name|
    result = has_light_spoken(light_name)
    unless result
      request_completed
    end

    light_name = light_name.strip
    light_id = get_light(light_name)

    if (!light_id.nil? and turn_off(light_id))
      if (rand(100) > 90)
        say "I have turned the " + light_name + " light off. Welcome to the dark side."
      else
        say "I have turned the " + light_name + " light off."
      end
    else
      say result
    end
    
    request_completed
  end

  #todo: Remove duplicate methods and merge regex
  listen_for /make(?: the)? (.*?) (dark|darker|Dr\.|doctor)/i do |light_name|
    light_name = light_name.strip
    light_id = get_light(light_name)

    if (light_id.nil?)
      say "You dont have a " + light_name + " light."
    else
      if (dim(light_id, 128))
        response = ask "I have dimmed the " + light_name + " light. Is that enough?"

        if(response =~ /yes/i)
          say "I knew you would like it!"
        else
          dim(light_id, 64)
          response = ask "How about now?"

          if(response =~ /yes/i)
            say "You are right, that does look better."
          else
            dim(light_id, 32)
            response = ask "And now?"

            if(response =~ /yes/i)
              say "You are right, that does look better."
            else
              dim(light_id, 10)
              say "You are right, that does look better."
            end
          end
        end
      else
        say result
      end
    end
    
    request_completed
  end

  #todo: Remove duplicate methods and merge regex
  listen_for /(?:darken|darker)(?: the)? (.*)/i do |light_name|
    light_name = light_name.strip
    light_id = get_light(light_name)

    if (light_id.nil?)
      say "You dont have a " + light_name + " light."
    else
      if (dim(light_id, 128))
        response = ask "I have dimmed the " + light_name + " light. Is that enough?"

        if(response =~ /yes/i)
          say "I knew you would like it!"
        else
          dim(light_id, 64)
          response = ask "How about now?"

          if(response =~ /yes/i)
            say "You are right, that does look better."
          else
            dim(light_id, 32)
            response = ask "And now?"

            if(response =~ /yes/i)
              say "You are right, that does look better."
            else
              dim(light_id, 10)
              say "You are right, that does look better."
            end
          end
        end
      else
        say result
      end
    end
    
    request_completed
  end

  listen_for /set(?: the)? ([a-z]*)(?: to)? ([0-9]*)(?: %)*/i do |light_name, value|
    light_name = light_name.strip
    print value + "\n"

    value_original = String.new(value)
    value = value.strip.to_f / 100.0
    value = value * 255.0
    light_id = get_light(light_name)

    if (light_id.nil?)
      say "You dont have a " + light_name + " light."
    else
      if (dim(light_id, value))
        value = value / 255.0
        value = value * 100.0
        response = ask "I have set the " + light_name + " light to " + value.to_s[0...-2] + "%, Do you want it any brighter or darker?"

        if (response =~ /dark/i)
          say "Okay, i made it a little darker."
          value = value_original.strip.to_f / 100.0
          value = (value * 255.0) - 50
          dim(light_id, value)
        elsif (response =~ /bright/i or response =~ /lighter/i )
          say "Okay, i made it a little brighter."
          value = value_original.strip.to_f / 100.0
          value = (value * 255.0) + 50
          dim(light_id, value)
        else
          say "Happy to be of service."
    request_completed
        end
      else
        say "I couldnt set the dimmer for the " + light_name + ", sorry about that."
	request_completed
      end
    end
    
    request_completed
  end

  listen_for /lights begin/i do
    response = `tdtool.py`
    say response
    printf(response)
    
    request_completed
  end

  listen_for /lights authenticate/i do
    response = `tdtool.py --authenticate`
    say response
    printf(response)

    request_completed
  end

  listen_for /lights/i do
    say "You can control these lights:\n" + get_lights_speakable

    request_completed
  end

  #todo: Remove example methods
  listen_for /where am i/i do
    say "Your location is: #{location.address}"
  end

  listen_for /test lights/i do
    say "Lights are up and running!" #say something to the user!

    request_completed #always complete your request! Otherwise the phone will "spin" at the user!
  end

  #Demonstrate that you can have Siri say one thing and write another"!
  listen_for /you don't say/i do
    say "Sometimes I don't write what I say", spoken: "Sometimes I don't say what I write"
  end

  #demonstrate state change
  listen_for /siri proxy test state/i do
    set_state :some_state #set a state... this is useful when you want to change how you respond after certain conditions are met!
    say "I set the state, try saying 'confirm state change'"

    request_completed #always complete your request! Otherwise the phone will "spin" at the user!
  end

  listen_for /confirm state change/i, within_state: :some_state do #this only gets processed if you're within the :some_state state!
    say "State change works fine!"
    set_state nil #clear out the state!

    request_completed #always complete your request! Otherwise the phone will "spin" at the user!
  end

  #demonstrate asking a question
  listen_for /siri proxy test question/i do
    response = ask "Is this thing working?" #ask the user for something

    if(response =~ /yes/i) #process their response
      say "Great!"
    else
      say "You could have just said 'yes'!"
    end

    request_completed #always complete your request! Otherwise the phone will "spin" at the user!
  end

  #demonstrate capturing data from the user (e.x. "Siri proxy number 15")
  listen_for /siri proxy number ([0-9,]*[0-9])/i do |number|
    say "Detected number: #{number}"

    request_completed #always complete your request! Otherwise the phone will "spin" at the user!
  end

  #demonstrate injection of more complex objects without shortcut methods.
  listen_for /test map/i do
    add_views = SiriAddViews.new
    add_views.make_root(last_ref_id)
    map_snippet = SiriMapItemSnippet.new
    map_snippet.items << SiriMapItem.new
    utterance = SiriAssistantUtteranceView.new("Testing map injection!")
    add_views.views << utterance
    add_views.views << map_snippet

    #you can also do "send_object object, target: :guzzoni" in order to send an object to guzzoni
    send_object add_views #send_object takes a hash or a SiriObject object

    request_completed #always complete your request! Otherwise the phone will "spin" at the user!
  end
end
