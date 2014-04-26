require 'rubygems'
require 'sinatra'

set :sessions, true

get '/form' do
  erb :form
end 

post '/myaction' do
  puts params['username']
end
# get '/inline' do 
#   "Hi, directly from the action!"
# end

# get '/template' do
#   erb :mytemplate, layout: 'layout'
# end

# get '/nested_template' do
#   erb :"/users/profile"
# end

# get '/nothere' do
#   redirect '/inline'
# end

