---
layout: post
title: "Track request time with the Faraday"
date: 2013-10-01 14:15
keywords: rails, faraday, middleware, remote request, track time, track request time, measure request time, faraday request time
categories: [Faraday, Middleware, Rails, Ruby]
---
I'm frequently find myself in need to measure request time of remote request from my application to an API or service. Previously, i used simple block of ruby code with `start_time` and `end_time`. Finally i decided to find out more robust method of doing so. I'm using `faraday` gem for remote requests, because it's easy extendable by middlewares and great overall. You can take a look at the project with collection of middlewares for faraday on [github](https://github.com/lostisland/faraday_middleware). This project contains ``Instrumentation`` middleware that we will use for tracking time of our request.

Before we start, here is an image of Dr. Faraday from LOST:

{% img center /images/posts/faraday-lost.jpg 'Faraday' %}

By the way github handle of faraday author is @**lost**island. Coincidence? I don't think so :)
<!--more-->

To the work! Let's look inside the [instrumentation middleware](https://github.com/lostisland/faraday_middleware/blob/master/lib/faraday_middleware/instrumentation.rb):
{% codeblock  instrumentation.rb %}
module FaradayMiddleware
  class Instrumentation < Faraday::Middleware
    dependency 'active_support/notifications'

    def initialize(app, options = {})
      super(app)
      @name = options.fetch(:name, 'request.faraday')
    end

    def call(env)
      ActiveSupport::Notifications.instrument(@name, env) do
        @app.call(env)
      end
    end
  end
end
{% endcodeblock %}
Pretty straightforward, we just instrument event `'request.faraday'`. If you are not familiar with the `ActiveSupport::Notifications` mechanism you can read about it [here](http://api.rubyonrails.org/classes/ActiveSupport/Notifications.html).

We should add this middleware to our faraday connection object:

{% codeblock  faraday_connection_example.rb %}
  def connection
    Faraday.new(url: "http://google.com") do |faraday|
      faraday.use FaradayMiddleware::Instrumentation
      faraday.adapter  Faraday.default_adapter
      faraday.response :logger
    end
  end
{% endcodeblock %}

Let's subscribe to the `request.faraday` events with the `ActiveSupport::Notifications`. You can execute any code inside your subscribe block, save information and time to the file or database for example. I will use rails logger in my example:

{% codeblock lang:ruby config/initializers/notifications.rb %}
ActiveSupport::Notifications.subscribe('request.faraday') do |name, starts, ends, _, env|
  url = env[:url]
  http_method = env[:method].to_s.upcase
  duration = ends - starts
  Rails.logger.info "#{url.host}, #{http_method}, #{url.request_uri}, takes #{duration} seconds"
end
{% endcodeblock %}

That's all, you are set and ready, whenever your application will send any request with the faraday connection, it will print request time information to your log file.