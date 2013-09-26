class StatusController < ApplicationController
  def index
  	available
    chart
  end

  def available
  	@ping = Ping.last()

   	unless @ping.nil?
   		@available = (Time.now - @ping[:time] > 10 ? true : false)
   	else
   		@available = 'unknown'
   	end
  end

  def chart

    @yesterdayChartData = Array.new((10 * 60 / 5), 0)
    @todayChartData = Array.new((10 * 60 / 5), 0)
    @averageChartData = Array.new((10 * 60 / 5), 0)

    pings = Ping.all()

    #This is set to today and tomorrow until we get more data.
    yesterday = Date.yesterday.to_time
    today = Date.today.to_time

    @day = nil
    @finalDay = nil
    @numDays = 0

    startTime = 9 * 60 * 60
    endTime = 18 * 60 * 60

    pings.each do |p|
      rawTime = p[:time] - p[:time].to_date.to_time
      if p[:time] > (yesterday.to_time + startTime) and p[:time] < (yesterday.to_time + endTime)
        #Do yesterday's buckets
        @yesterdayChartData[(rawTime / (60 * 5)).to_int - (startTime / (60 * 5))] += 1
      elsif p[:time] > (today.to_time + startTime) and p[:time] < (today.to_time + endTime)
        #Do Today's buckets
        @todayChartData[(rawTime / (60 * 5)).to_int - (startTime / (60 * 5))] += 1
      end

      if (p[:time] > p[:time].to_date.to_time + startTime) and (p[:time] < p[:time].to_date.to_time + endTime)
        @averageChartData[(rawTime / (60 * 5)).to_int - (startTime / (60 * 5))] += 1
      end


      if @day.nil? or p[:time].to_date > @day
        @day = p[:time].to_date
        @numDays += 1
        puts "Incrementing Days #{@numDays}"
      end

      @finalDay = p[:time].to_date
    end

    unless @numDays == 0
      @averageChartData.map!{
          |n| n / @numDays
      }
    end

    #TODO: add average data points
    @hitsChart = LazyHighCharts::HighChart.new('graph') do |f|
      f.title({ :text=>"Ping Pong Data"})
      f.legend({:align => 'right',
                :x => -100,
                :verticalAlign=>'top',
                :y=>20,
                :floating=>"true",
                :backgroundColor=>'#FFFFFF',
                :borderColor=>'#CCC',
                :borderWidth=>1,
                :shadow=>"false"
               })
      f.options[:yAxis][:title] = {:text=>"Detections"}
      f.options[:xAxis][:title] = {:text=>"Time"}
      f.series(:type=> 'spline',:name=> 'Yesterday', :data=> @yesterdayChartData)
      f.series(:type=> 'spline',:name=> 'Today', :data=> @todayChartData)
      f.series(:type=> 'spline',:name=> 'Average', :data=> @averageChartData)

    end
  end

end
