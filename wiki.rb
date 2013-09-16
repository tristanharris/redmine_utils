require 'rubygems'
require 'rest_client'
require 'json'

class RedmineClient

	def initialize(server, api_key)
		@server, @api_key = server, api_key
	end

	def get(url)
		JSON.parse RestClient.get("http://#{@api_key}@#{@server}#{url}.json")
	end

	def put(url, data)
		#puts "http://#{API_KEY}@#{SERVER}#{url}.json", data
		RestClient.put("http://#{@api_key}@#{@server}#{url}.json", data, :content_type => :json, :accept => :json) do |response, request, result|
			#puts response.code
			#puts response.inspect
			#$r=[request,response,result]
		end
	end

end

class WikiPage
	
	FIELDS = %w(title version created_on updated_on text)

	attr_reader *FIELDS
	attr_writer :text

	def self.all
		Client.get('/projects/drthom/wiki/index')['wiki_pages'].map{|i| self.new(i)}
	end

	def self.find(page_title)
		new.tap{|o| o.send :populate, o.send(:load, page_title)}
	end

	def initialize(data={})
		populate(data)
	end

	def text
		populate load(title) if @text.nil?
		@text
	end

	def save
		Client.put("/projects/drthom/wiki/#{title}", {'wiki_page' => {'text' => text, 'version' => version}})
	end

	private
	def load(title)
		Client.get("/projects/drthom/wiki/#{title}")['wiki_page']
	end

	def populate(data)
		FIELDS.each do |field|
			self.instance_variable_set('@'+field, data[field])
		end
	end

end

