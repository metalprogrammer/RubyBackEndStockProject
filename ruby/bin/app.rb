require 'sinatra'
require 'yahoo-finance'
require 'sinatra/cross_origin'

set :port, 8080
set :static, true
set :public_folder, "static"
set :views, "views"

stockList = [];
symbolList = []

def updateStockList(name,stockList, symbolList)
	count = 0
	File.open(name, "r") do |f|
		f.each_line do |line|
			if count > 0
				split = line.split(",")
				stockList<<split[1]
				symbolList<<split[0]
			end
			count += 1
		end
	end
end

def toJson(stockList,symbolList)
	json = '{"stocklisting": {"id": "stockList","listofstocks": ['
	entry = ']} ,"stocks":['
	id = '"id"'
	name = '"name"'
	symbol = '"symbol"'
	for i in 0..stockList.count-1
		json += (i + 1).to_s
		entry += "{#{id}:#{i + 1}, #{name} : \"#{stockList[i].delete('"')}\" , #{symbol} : \"#{symbolList[i].delete('"')}\" }"
		if i < (stockList.count - 1)
			json += ","
			entry += ","
		end
	end
	return json +entry + "]}"
end


updateStockList("companylist.csv",stockList,symbolList)
jsonList = toJson(stockList,symbolList)
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