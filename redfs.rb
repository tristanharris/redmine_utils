require "rubygems"
require 'rfusefs'
include FuseFS
require './wiki'
require 'yaml'

Config = YAML.load_file('config.yml')
Client = RedmineClient.new(Config[:server], Config[:api_key])

class RedFS < FuseFS::FuseDir

	def initialize
		@dir_list = {}
		@file_list = {}
	end

  def contents(path)
		debug "contents: #{path}"
		return [] unless path == '/'
    @dir_list[path] = WikiPage.all.map(&:title)
  end

  def file?(path)
		debug "is file: #{path}"
    title, rest = split_path(path)
    dir_list(File.dirname(path)).include?(title)
  end

  def read_file(path)
		debug "read: #{path}"
		load_page(path).text
  end

  def size(path)
		debug "size: #{path}"
    read_file(path).size
  end

	def can_write?(path)
		debug "can_write: #{path}"
		file? path
	end

	def write_to(path, body)
		debug "write: #{path}"
		@file_list[path] = nil
		load_page(path).tap{|p| p.text = body}.save
	end

	private
	def dir_list(path)
		@dir_list[path] || contents(path)
	end

	def load_page(path)
		title, rest = split_path(path)
		file, loaded_at = @file_list[path]
		if loaded_at.nil? || Time.now - loaded_at > 1000
			file = WikiPage.find(title)
			@file_list[path] = [file, Time.now]
		end
		file
	end

	def debug(msg)
		#puts msg
	end

end

if (File.basename($0) == File.basename(__FILE__))
  unless (ARGV.length > 0 && File.directory?(ARGV[0]))
    puts "Usage: #{$0} <mountpoint> <mount_options>"
    exit
  end

  root = RedFS.new

  # Set the root FuseFS
  FuseFS.start(root,*ARGV)

end
