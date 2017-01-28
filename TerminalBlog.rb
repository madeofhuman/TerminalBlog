#!/usr/bin/ruby

require 'rubygems'
require 'optparse'
require 'ostruct'
require 'google/apis/blogger_v3'
require 'google/api_client/client_secrets'
require 'json'
require 'launchy'

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

def getBlogId
	print "Enter your blogId: "
	@blogId = STDIN.gets.to_i
	postToBloggerService
end

def argvCheck
	puts "...checking arguments..."
	sleep(1)
	if @args.size < 2 && @args[0] != "-h"
		puts "-h for help"
		puts "Posts are uploaded as drafts by default.\nUse --publish if you want to publish immediately"
		exit
	else
		argvHandle
	end
end

def argvHandle
	puts "...processing arguments..."
	sleep(1)
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

def requireTitle(draft,title)
	puts "...checking for title..."
	sleep(1)
	if draft == false && title == 'Default Title'
		abort("You must provide a title if you want to publish.")
	end
	authenticate
end

def authenticate
	puts "...authenticating with Blogger..."
	sleep(1)
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

def initBloggerService(authClient)
	puts "...initializing Blogger service..."
	sleep(1)
	@Blogger = Google::Apis::BloggerV3
	@service = @Blogger::BloggerService.new
	@service.authorization = authClient
	readFile
end

def readFile
	puts "...reading blog file..."
	sleep(1)
	begin
		@f = File.read(@postfile)
	rescue Exception => e
		abort("Error opening file. Aborting...")
	end
	buildLabelList
end

def buildLabelList
	puts "...attaching labels..."
	sleep(1)
	@labels_list = @labels.split(',')
	buildBodyObject
end

def buildBodyObject
	puts "...creating blog post..."
	sleep(1)
	@body = {
		"content": @f,
		"title": @title,
		"labels": @labels_list
	}
	getBlogId
end

def postToBloggerService
	puts "...posting to Blogger..."
	sleep(1)
	begin
		@post = @service.insert_post(@blogId, post_object = @body, is_draft: @isDraft)
	rescue Exception => e
		abort("Google didn't like our post :(")
	end
	displayPostsMetadata
end

def displayPostsMetadata
	puts "...generating operation details..."
	sleep(1)
	puts "Title: %s" % @post.title
	puts "isDraft: %s" % @isDraft
	if @isDraft == false
		puts "URL: %s" % @post.url
	end
	puts "Labels: %s" % @post.labels
end

puts "...initializing..."
sleep(1)
argvCheck