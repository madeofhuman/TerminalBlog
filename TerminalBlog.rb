require 'rubygems'
require 'optparse'
require 'ostruct'
require 'google/apis/blogger_v3'
require 'google/api_client/client_secrets'
require 'json'
require 'launchy'

blogId = 0 			# the blog id
isDraft = true 			# option to upload as draft. --publish argument overrides it
postfile = '' 			# path to blogpost file
title = 'Default Title' 			# default post title. -t argument overrides it
labels = "label, label1" 			# default. comma delimited list of labels for post. -l argumene overrides it

# check for incomplete argument and direct to help
if ARGV.size < 2 && ARGV[0] != "-h"
	puts "-h for help"
	puts "Posts are uploaded as drafts by default.\nUse --publish if you want to publish immediately"
end

# handle the arguments
options = OpenStruct.new
OptionParser.new do |opt|
	opt.on('-f FI/LE/PATH', 'The path to the blogpost file') do |o|
		postfile = o
	end
	opt.on('-t "My Title"', 'The blogpost title') do |o|
		title = o
	end
	opt.on('-l "label, label1"', 'Comma-deliminated list of labels for the post') do |o|
		labels = o
	end
	opt.on('--publish','Publish the post directly, instead of uploading as draft') do |o|
		isDraft = false
	end
	opt.on('Example: TerminalBlog.rb -f path/to/file.txt -t "Terminal Post" -l "terminal, post" --publish')
end.parse!

# require post title before publishing
if isDraft == false && title == 'Default Title'
	abort("You must provide a title if you want to publish.")
end

# if there is no userkey, authenticate with Google and save the key
if File.exist?("userkey") == false
	# Launchy.open("http://google.com")
	client_secrets = Google::APIClient::ClientSecrets.load
	auth_client = client_secrets.to_authorization
	auth_client.update!(:scope => 'https://www.googleapis.com/auth/blogger',
		:redirect_uri => 'urn:ietf:wg:oauth:2.0:oob')

	auth_uri = auth_client.authorization_uri.to_s
	Launchy.open(auth_uri)

	puts 'Paste the code from the auth response page'
	auth_client.code = gets
	auth_client.fetch_access_token!

	blogger = Google::Apis::BloggerV3::BloggerService.new
	blogger.authorization = auth_client

	# store key for future reference
	userkey = File.new("userkey","w")
	userkey.puts(auth_client.code)
else
	userkey = File.read("userkey")
	auth_client_code = userkey
	auth_client.fetch_access_token!
end