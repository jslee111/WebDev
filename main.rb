require 'rubygems'
require 'sinatra'

set :sessions, true

helpers do 
  def calculate_total(cards) # card is [["H","3"], ["D", "J"], ...]
      arr = cards.map{|e| e[1] }

      total = 0
      arr.each do |a|
        if a == "A"
          total += 11
        else
          total += a.to_i == 0? 10 : a.to_i
        end
      end

      #correct for Aces
      arr.select{|e| e == "A"}.count.times do
        break if total <=21
        total -= 10
      end

      total
  end

  def card_image(card) #['H', '4']
    suit = case card[0]
        when 'H' then 'hearts'
        when 'D' then 'diamonds'
        when 'C' then 'clubs'
        when 'S' then 'Spades'
    end 

    value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(value) 
        value = case card[1]
          when 'J' then 'jack'
          when 'Q' then 'queen'
          when 'K' then 'king'
          when 'A' then 'ace'
        end
      end 

    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"

  end
end

before do 
  @show_hit_or_stay_buttons = true
end 

get '/' do 
  if session[:player_name]
    #progress to the game
    redirect '/game'
  else
    redirect '/new_player' 
  end
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "Name is required"
    halt erb(:new_player)
  end

  session[:player_name] = params[:player_name]
  #progress to the game
  redirect '/game'
end

get '/game' do
  #create a deck and put it in session
  suits = ['S','H','D','C'] 
  values = ['A','2','3','4','5','6','7','8','9','10','J','Q','K'] 
  session[:deck] = (suits.product(values)*6).shuffle!

  #deal cards
  session[:dealer_cards] =[]
  session[:player_cards] =[]
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  
    #dealer cards
    #player cards

  erb :game
end 

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  # @some_variable = "hi"
  player_total = calculate_total(session[:player_cards])
  if player_total == 21
    @success = "Congratulations! #{session[:player_name]} hit blackjack"
     @show_hit_or_stay_buttons = false
  else calculate_total(session[:player_cards]) > 21 ##no space between function name and session bracket
      @error = "Sorry, it looks like #{session[:player_name]} busted."
      @show_hit_or_stay_buttons = false
  end

  erb :game
end

post '/game/player/stay' do
  @success = " #{session[:player_name]} has chosen to stay."
  @show_hit_or_stay_buttons = false
  erb :game
end


# get '/form' do
#   erb :form
# end 

# post '/myaction' do
#   puts params['username']
# end
# # get '/inline' do 
# #   "Hi, directly from the action!"
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

