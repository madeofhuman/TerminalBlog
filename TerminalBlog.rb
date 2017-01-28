#!/usr/bin/ruby

require 'rubygems'
require 'optparse'
require 'ostruct'
require 'google/apis/blogger_v3'
require 'google/api_client/client_secrets'
require 'json'
require 'launchy'

class TerminalBlog

	@blogId = '' 			# the blog id
	@isDraft = true 			# option to upload as draft. --publish argument overrides it
	@postfile = '' 			# path to blogpost file
	@f = nil  			# the read file
	@title = 'Default Title' 			# default post title. -t argument overrides it
	@labels = "label, label1" 			# default, comma-delimited list of labels for the post. -l argument overrides it
	@body = nil
	@options = nil
	@client_secrets = nil
	@auth_client = nil
	@Blogger = nil
	@service = nil
	@args = ARGV

	def self.getBlogId
		print "Enter your blogId: "
		@blogId = STDIN.gets.to_i
		postToBloggerService
	end

	def self.argvCheck
		puts "...checking arguments..."
		wait
		if @args.size < 2 && @args[0] != "-h"
			puts "-h for help"
			puts "Posts are uploaded as drafts by default.\nUse --publish if you want to publish immediately"
			exit
		else
			argvHandle
		end
	end

	def self.argvHandle
		puts "...processing arguments..."
		wait
		@options = OpenStruct.new
		OptionParser.new do |opt|
			opt.on('-f FI/LE/PATH', 'The path to the blogpost file') do |o|
				@postfile = o
			end
			opt.on('-t "My Title"', 'The blogpost title') do |o|
				@title = o
			end
			opt.on('-l "label, label1"', 'Comma-deliminated list of labels for the post') do |o|
				@labels = o
			end
			opt.on('--publish','Publish the post directly, instead of uploading as draft') do |o|
				@isDraft = false
			end
			opt.on('Example: TerminalBlog.rb -f path/to/file.txt -t "Terminal Post" -l "terminal, post" --publish')
		end.parse!
		requireTitle(@isDraft,@title)
	end

	def self.requireTitle(draft,title)
		puts "...checking for title..."
		wait
		if draft == false && title == 'Default Title'
			abort("You must provide a title if you want to publish.")
		end
		authenticate
	end

	def self.authenticate
		puts "...authenticating with Blogger..."
		wait
		@client_secrets = Google::APIClient::ClientSecrets.load("client_secrets.json")
		@auth_client = @client_secrets.to_authorization
		@auth_client.update!(:scope => 'https://www.googleapis.com/auth/blogger',
			:redirect_uri => 'urn:ietf:wg:oauth:2.0:oob')
		if File.exist?("userkey") == false
			auth_uri = @auth_client.authorization_uri.to_s
			Launchy.open(auth_uri)

			print 'Paste the code from the auth response page: '
			credential = gets
			@auth_client.code = credential
			@auth_client.fetch_access_token!

			# store key for future reference
			userkey = File.new("userkey","w")
			userkey.puts(@auth_client.fetch_access_token.to_s)
			initBloggerService(@auth_client)
		else
			credential = File.read("userkey")
			@auth_client.code = credential
			@auth_client.fetch_access_token!
			initBloggerService(@auth_client)
		end
	end

	def self.initBloggerService(authClient)
		puts "...initializing Blogger service..."
		wait
		@Blogger = Google::Apis::BloggerV3
		@service = @Blogger::BloggerService.new
		@service.authorization = authClient
		readFile
	end

	def self.readFile
		puts "...reading blog file..."
		wait
		begin
			@f = File.read(@postfile)
		rescue Exception => e
			abort("Error opening file. Aborting...")
		end
		buildLabelList
	end

	def self.buildLabelList
		puts "...attaching labels..."
		wait
		@labels_list = @labels.split(',')
		buildBodyObject
	end

	def self.buildBodyObject
		puts "...creating blog post..."
		wait
		@body = {
			"content": @f,
			"title": @title,
			"labels": @labels_list
		}
		getBlogId
	end

	def self.postToBloggerService
		puts "...posting to Blogger..."
		wait
		begin
			@post = @service.insert_post(@blogId, post_object = @body, is_draft: @isDraft)
		rescue Exception => e
			abort("Google didn't like our post :(")
		end
		displayPostsMetadata
	end

	def self.displayPostsMetadata
		puts "...generating operation details..."
		wait
		puts "Title: %s" % @post.title
		puts "isDraft: %s" % @isDraft
		if @isDraft == false
			puts "URL: %s" % @post.url
		end
		puts "Labels: %s" % @post.labels
	end

	def self.wait
		sleep(1)
	end

	def self.tblog
		puts "...initializing..."
		wait
		argvCheck
	end

	tblog
end