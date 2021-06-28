class HomeController < ApplicationController
  include HTTParty

  def index

  end

  def solve
    events_info = params["_json"]
    events = Hash.new
    events_info.each do |event|
      id = event["id"].to_s.split("#")[0]
      start_date = Time.at(event["start_date"] / 1000).utc
      end_date = Time.at(event["end_date"] / 1000).utc  
      if not events.key?(id)
        events[id] = Hash.new
        events[id]["start"] =  start_date.hour * 60 + start_date.min
        events[id]["end"] =  end_date.hour * 60 + end_date.min
        if end_date.hour == 0 and end_date.min == 0
          events[id]["end"] =  24 * 60
        end
        events[id]["date"] = [(start_date.to_date - Date.new(2021,5,31)).to_i]
        events[id]["text"] = event["text"]
      else
        if (start_date.hour * 60 + start_date.min) != events[id]["start"]
          render plain: 'Error: series invalid or inconsistent', layout: "no_toolbar"
          return
        else
          events[id]["date"].append((start_date.to_date - Date.new(2021,5,31)).to_i)
        end
      end

      if start_date.to_date != end_date.to_date
        if not ((end_date.to_date == start_date.to_date + 1) and end_date.hour == 0 and end_date.min == 0) #boundary exception
          render plain: 'Error: events spanning multiple days are not supported', layout: "no_toolbar"
          return
        end 
      end
    end

    #puts "events"
    #puts events
    groups = Hash.new
    events.each do |_, event|
      if not groups.key?(event["text"])
        groups[event["text"]] = {length: event["end"] - event["start"], data: []}
      end
      if groups[event["text"]][:length] != (event["end"] - event["start"])
        #puts groups[event["text"]][:length]
        #puts (event["end"] - event["start"])
        render plain: 'Error: events with the same name have to have the same length', layout: "no_toolbar"
        return
      end
      groups[event["text"]][:data].append([[event["start"]], event["date"]])
    end
    
    #puts "groups"
    #puts groups

    body = [[], [], []]
    groups.each do |key, value|
      body[0].append(value[:data])
      body[1].append(value[:length])
      body[2].append(key)
    end

    results = HTTParty.post("http://fathomless-everglades-11877.herokuapp.com/rdsolve",
      :body => {:schedules => body[0], 
               :lengths => body[1]}.to_json,
               :headers => {'Content-Type' => 'application/json'})

    if results.nil?
      render plain: 'Error: all events could not be accommodated', layout: "no_toolbar"
      return
    end

    #Transform into {text, start, end} hashes               
    @hashes = []
    results.each_with_index do |result, i|
      start_time = result[0]
      end_time = result[0] + body[1][i]
      text = body[2][i]
      (1...result.length).each do |j|
        date = Date.new(2021,5,31) + result[j]
        start_date = DateTime.new(date.year, date.month, date.day, start_time / 60, start_time % 60)
        end_date = DateTime.new(date.year, date.month, date.day, end_time / 60, end_time % 60)
        @hashes.append({text: text, start_date: start_date.strftime('%Y-%m-%d %H:%M'), end_date: end_date.strftime('%Y-%m-%d %H:%M')})
      end
    end

    #puts results.to_s
    #puts @hashes
    #puts body.to_s

    render :show, layout: "no_toolbar"
    #render plain: results
    #return
  end

  def show
    @hashes = params["_json"]
    render :show, layout: "no_toolbar"
  end

  def examples

  end
end
