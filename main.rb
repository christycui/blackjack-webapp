require 'rubygems'
require 'sinatra'

use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'notgonnatellyou' 

BLACKJACK_AMT = 21
DEALER_HIT_MIN = 17

helpers do
  def calculate_total(cards)
    # calculate initial total
    total = 0
    cards.each do |card| 
      if card[0] == 'A'
        total += 11
      elsif ['J','Q','K','1'].include?card[0]
        total += 10 
      else
        total += card[0].to_i
      end
    end
    # correct for Aces
    count = cards.select {|card| card[0] == 'A'}.count
    while count > 0 and total > BLACKJACK_AMT
      total -= 10
      count -= 1
    end
    # returns total
    total
  end

  def end_game?
    if session[:player_card]
      if calculate_total(session[:player_card]) == BLACKJACK_AMT
        @success = 'Congratulations!! You hit blackjack!'
        @player_win = 'Y'
      elsif calculate_total(session[:player_card]) > BLACKJACK_AMT
        @error = 'Oh no! You busted. :/'
      elsif calculate_total(session[:dealer_card]) == BLACKJACK_AMT
        @error = 'Dealer hit blackjack! You lost.'
      elsif calculate_total(session[:dealer_card]) > BLACKJACK_AMT
        @success = 'Dealer busted! You won!'
        @player_win = 'Y'
      elsif calculate_total(session[:player_card]) > calculate_total(session[:dealer_card])
        @success = "You just won $#{session[:bet]}!!"
        @player_win = 'Y'
      elsif calculate_total(session[:player_card]) < calculate_total(session[:dealer_card])
        @error = "You just lost $#{session[:bet]}."
      end
    end
  end
end

before do
  @turn = 'player'
end

get '/' do
  erb :get_username
end

post '/' do
  session[:username] = params[:username]
  session[:balance] = "500.00"
  redirect '/bet' if session[:username] != ''
  @error = 'Please enter a name.' if session[:username] == '' or session[:username].nil?
  erb :get_username
end

get '/bet' do
  @error = "You ran out of money! Please start a new game." if session[:balance].to_f <= 0
  redirect '/set_username' if !session[:username]
  erb :set_bet
end

get '/set_username' do 
  redirect '/bet' if session[:username]
  @error = 'Please enter a name first.'
  erb :get_username
end

post '/bet' do
  redirect '/' if !session[:username]
  if params[:bet].include?('.')
    session[:bet] = params[:bet].split('.')[0] + '.' + params[:bet].split('.')[1].ljust(2,'0')
  else
    session[:bet] = params[:bet] + '.00'
  end
  if session[:bet].to_f > session[:balance].to_f
    @error = "Woops! Looks like you don't have $#{params[:bet]} with you. "
  elsif session[:bet].to_f == 0 || (params[:bet].to_f.to_s != params[:bet] && params[:bet].to_i.to_s != params[:bet])
    @error = "Please enter a number."
  elsif session[:bet].to_f < 0 or session[:bet].to_f.zero?
    @error = "Your bet has to be bigger than $0."
  elsif (session[:bet].split('.')[1].length > 2 rescue false) 
    @error = "Please enter a valid dollar amount."
  elsif session[:bet].to_f <= session[:balance].to_f && session[:bet].to_f > 0
    redirect '/new_game'
  end
  erb :set_bet
end

get '/new_game' do
  @deal = 'Y'
  # create a deck
  suit = ['Hearts', 'Diamonds', 'Clubs', 'Spades']
  face_value = *(2..10)
  face_value.push('Ace', 'Jack', 'Queen', 'King')
  session[:deck] = face_value.product(suit).map {|card| card.join(" of ")}.shuffle!
  
  # deal cards
  session[:player_card] = session[:deck].pop(2)
  session[:dealer_card] = session[:deck].pop(2)
  if calculate_total(session[:player_card]) >= 21
    redirect '/result'
  else
   @success = "Welcome, #{session[:username]}!"
  end
  erb :game
end

get '/player/hit' do
  @player_deal = 'Y'
  session[:player_card] << session[:deck].pop
  @info = "You chose to hit! Your new card is #{session[:player_card][-1]}."
  redirect '/result' if calculate_total(session[:player_card]) >= BLACKJACK_AMT
  erb :game
end

get '/player/stay' do
  @info = 'You chose to stay!'
  @turn = 'dealer'
  redirect '/result' if calculate_total(session[:dealer_card]) >= BLACKJACK_AMT
  erb :game
end

get '/dealer/hit' do
  @dealer_deal = 'Y'
  @turn = 'dealer'
  @info = "Dealer hit at #{calculate_total(session[:dealer_card])}. A new card is dealt."
  session[:dealer_card] << session[:deck].pop
  erb :game
end

get '/result' do
  @turn = 'end'
  end_game?
  erb :game
end

get '/bye' do
  erb :bye
end

