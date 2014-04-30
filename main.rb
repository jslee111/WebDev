require 'rubygems'
require 'sinatra'
require 'pry'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17
INITIAL_POT_AMOUNT = 10000

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
        break if total <=BLACKJACK_AMOUNT
        total -= 10
      end

      total
  end

  def card_image(card) #['H', '4']
    suit = case card[0]
        when 'H' then 'hearts'
        when 'D' then 'diamonds'
        when 'C' then 'clubs'
        when 'S' then 'spades'
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

  def winner!(msg)
    @play_again=true
     @show_hit_or_stay_buttons = false
     session[:player_pot] = session[:player_pot] + session[:player_bet]
     @winner = "<strong>#{session[:player_name]} wins! </strong> #{msg}"
  end 
  
  def loser!(msg)
    @play_again=true
     @show_hit_or_stay_buttons = false
      session[:player_pot] = session[:player_pot] - session[:player_bet]
    @loser ="<strong> #{session[:player_name]} loses. </strong> #{msg}" 
  end  

  def tie!(msg)
    @play_again=true
     @show_hit_or_stay_buttons = false
    @winner ="<strong> It's a tie!</strong>#{msg}"
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
  session[:player_pot]=INITIAL_POT_AMOUNT
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "Name is required"
    halt erb(:new_player)
  end

  session[:player_name] = params[:player_name]
  #progress to the game
  redirect '/bet'
end

get '/bet' do
  session[:player_bet] = nil
  erb :bet
end

post '/bet' do
  if params[:bet_amount].nil? || params[:bet_amount].to_i ==0
      @error= "Must make a bet"
      halt erb(:erb)
  elsif params[:bet_amount].to_i > session[:player_pot]
    @error = "Bet amount cannot be greater than what you have ($#{session[:player_pot]})"
    halt erb(:erb)
  else ##happy path
    session[:player_bet] = params[:bet_amount].to_i
    redirect '/game'
  end
end

get '/game' do

  session[:turn] = session[:player_name]
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
  if player_total == BLACKJACK_AMOUNT
    winner!("#{session[:player_name]} hit blackjack.")
    
  elsif player_total > BLACKJACK_AMOUNT ##no space between function name and session bracket
      loser! ("It looks like #{session[:player_name]} busted at #{player_total}.")
  end 

  erb :game, layout: false
end

post '/game/player/stay' do
  @success = " #{session[:player_name]} has chosen to stay."
  @show_hit_or_stay_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = "dealer"
  @show_hit_or_stay_buttons = false

  # decision tree
  dealer_total = calculate_total(session[:dealer_cards])
  
  if dealer_total ==BLACKJACK_AMOUNT
    loser!("Dealer hit blackjack")
  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("Dealer busted at #{dealer_total}.")
  elsif dealer_total >=DEALER_MIN_HIT #17, 18, 19, and 20
    #dealer stays
    redirect '/game/compare'
  else 
    #dealer hits
    @show_dealer_hit_button = true
  end 

  erb :game, layout: false
end

post '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect 'game/dealer'
end

get '/game/compare' do
  @show_hit_or_stay_buttons = false

  player_total = calculate_total (session[:player_cards])
  dealer_total = calculate_total (session[:dealer_cards])


  if player_total < dealer_total 
    # @error = "Sorry, you lost."
    loser!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")

  elsif player_total > dealer_total 
    # @success = "Congrats, you won!"
    winner!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  else 
    # @success = "It's a tie!"
    tie!(" Both #{session[:player_name]} and the dealer stayed at #{player_total}.")
  end

  erb :game, layout: false
end

get '/game_over' do 
  erb :game_over
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

