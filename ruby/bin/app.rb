require 'sinatra'
require 'yahoo-finance'
require 'sinatra/cross_origin'

set :port, 8080
set :static, true
set :public_folder, "static"
set :views, "views"


class StockData
	attr_accessor :stock 
	attr_accessor :symbol
	
	def initialize(stock, symbol)
      @stock=stock
      @symbol=symbol
   end
	
end

stocks = []

def updateStockList(name,stocks)
	count = 0
	File.open(name, "r") do |f|
		f.each_line do |line|
			if count > 0
				split = line.split(",")
				name = split[1]
				sym = split[0]
				stocks << StockData.new(name, sym)
			end
			count += 1
		end
	end
end

def toJson(stocks)
	json = '{"stocklisting": {"id": "stockList","listofstocks": ['
	entry = ']} ,"stocks":['
	id = '"id"'
	name = '"name"'
	symbol = '"symbol"'
	for i in 0..stocks.count-1
		json += (i + 1).to_s
		entry += "{#{id}:#{i + 1}, #{name} : \"#{stocks[i].stock.delete('"')}\" , #{symbol} : \"#{stocks[i].symbol.delete('"')}\" }"
		if i < (stocks.count - 1)
			json += ","
			entry += ","
		end
	end
	return json +entry + "]}"
end


updateStockList("companylist1.csv",stocks)
updateStockList("companylist2.csv",stocks)
updateStockList("companylist3.csv",stocks)
stocks.sort{|x,y| x.stock.capitalize  <=> y.stock.capitalize }

jsonList = toJson(stocks)
# ...


register Sinatra::CrossOrigin
configure do
  enable :cross_origin
end

options "*" do
  response.headers["Allow"] = "HEAD,GET,PUT,DELETE,OPTIONS"

  # Needed for AngularJS
  response.headers["Access-Control-Allow-Headers"] = "X-Requested-With, X-HTTP-Method-Override, Content-Type, Cache-Control, Accept"

  halt HTTP_STATUS_OK
end

get '/' do
end

get '/historicaldata/:val' do
	yahoo_client = YahooFinance::Client.new
	data = yahoo_client.historical_quotes( params['val'], { start_date: Time::now-(24*60*60*30), end_date: Time::now })
	his = '"historicaldatas"'
	id = '"id"'
	ret = "{#{his}: {#{id}: \"#{params['val']}\", \"name\":\"#{params['val']}\", \"listofdata\":["
	sData = "]}, \"stockdatas\":["
	
	date = '"date"'
	average = '"average"'
	
	for i in 0..(data.count - 1)
		ret += (i+1).to_s
		
		avg = (data[i].low.to_f + data[i].open.to_f + data[i].close.to_f + data[i].high.to_f)/4
		
		day = Time::now-(24*60*60*i)
		
		sData += "{#{id}:#{i + 1}, #{date}: \"#{day}\", #{average}:#{avg}}"
		
		if i < data.count - 1
			sData +=","
			ret +=","
		end
		#ret += data[i].ask
	end
	return ret + sData +"]}"
end

get '/hello/' do
	print("stock")
    greeting = params[:greeting] || "Hi There"
    erb :index, :locals => {'greeting' => greeting}
end

get '/stocks/' do
	return '{"stocks": [{"id": 1,"title":"abcc","stockList": [1, 2, 3]}],"stock": [{"id": 1, "name": "app"},{"id": 2,"name": "xyz"},{"id": 3,"name": "foo"}]}'
end

get '/stocklisting/:id' do
	#return '{"stockslisting": {"title":"abcc", "abcs":"AA"}}';
	return '{"stocks": {"id": 1,"title":"abcc","stockList": [1, 2, 3]},"stock": [{"id": 1, "name": "app"},{"id": 2,"name": "xyz"},{"id": 3,"name": "foo"}]}'

end

get '/stocklistings/:id' do
	return jsonList
end

get '/stocks/:id' do
	#return '{"stockslisting": {"title":"abcc", "abcs":"AA"}}';
	#return '{"stocks": {"id": 1,"stockList": [1, 2, 3]},"stock": [{"id": 1, "name": "app"},{"id": 2,"name": "xyz"},{"id": 3,"name": "foo"}]}'
	return jsonList
end