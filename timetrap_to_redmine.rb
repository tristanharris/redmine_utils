require 'rubygems'
require 'timetrap'
require 'rest_client'
require 'json'
require 'date'
require 'active_support/core_ext/time/conversions'

class Issue
	
	def self.find(id)
		new(JSON.parse(RestClient.get("http://API_KEY@SERVER/issues/#{id}.json"))['issue'])
	end

	def initialize(data)
		@data = data
	end

	def id
		@data['id']
	end

	def subject
		@data['subject']
	end

	def tracker
		@data['tracker']['name']
	end

	def log_time(time)
		RestClient.post("http://API_KEY@SERVER/issues/#{id}/time_entries.json", time.to_json, :content_type => :json, :accept => :json)
	end

end

class TimeEntry
	attr_accessor :hours, :spent_on, :comments, :activity

	def initialize(hours, spent_on, comments, activity)
		@hours, @spent_on, @comments, @activity = hours, spent_on, comments, activity
	end

	def to_json
		{:time_entry => {:hours => @hours, :spent_on => @spent_on, :comments => @comments, :activity_id => @activity}}.to_json
	end

end

feature_activity = {'Bug' => 10, 'Feature' => 9, 'Support' => 11, 'Maintenance' => 10, 'Wishlist' => 9, 'Action' => 13}
sheet = 'mohc'
end_date = Date.today - Date.today.cwday

entries = Timetrap::Entry.filter('sheet = ?', sheet).filter('start < ?', end_date)

entries.each do |entry|
	matches = entry.note.scan(/RM(\d+)/)
	if !matches.empty?
		id = matches[0].first
		issue = Issue.find(id)
		t = TimeEntry.new(entry.duration/60.0/60.0, entry.start.to_date, entry.id.to_s + ': ' + entry.note, feature_activity[issue.tracker])
		puts t.inspect
		issue.log_time(t)
		ok = entry.update :sheet => 'processed'
		raise 'Could not update timetrap' unless ok
	end
	if ['Timesheet', 'DT Teleconf'].include? entry.note
		puts "untracked #{entry.note} (#{entry.id})"
		ok = entry.update :sheet => 'untracked'
		raise 'Could not update timetrap' unless ok
	end
end


#issue = Issue.find(543)

#t = TimeEntry.new(5.5, Date.today, 'Just a test', feature_activity[issue.tracker])

#puts issue.inspect
#puts t.inspect

begin
#issue.log_time(t)
rescue Exception => e
puts e.inspect
end
