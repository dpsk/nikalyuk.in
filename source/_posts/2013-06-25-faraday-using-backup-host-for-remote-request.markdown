---
layout: post
title: "Faraday - using backup host for remote requests"
date: 2013-06-25 14:42
comments: true
keywords: rails, faraday, middleware, remote request, backup host, mirror
categories: [Faraday, Middleware, Rails, Ruby]
---

Nowadays almost every Rails application interact with the remote service or API. The problem is that you can't fully trust those services and you forced to add a lot of test coverage and exception handling for this part of code. Once i worked with the API that had mirror server for case when the main one is unavailable. I write a middleware for [Faraday](https://github.com/lostisland/faraday), which will use backup host(provided by user) if the original one is unresponsive.

<!--more-->

First of all, what is Faraday? It's an awesome HTTP client library that provides a common interface over many adapters (such as Net::HTTP) and embraces the concept of Rack middleware when processing the request/response cycle. Middleware are classes that implement a call instance method. They hook into the request/response cycle. Our middleware will be hooked to the request cycle.

Now to our middleware. All we need from it is simple checking for errors, such as `Faraday::Error::TimeoutError` or `Faraday::ConnectionFailed`. If some errors from the list were araised, than we should switch request to the backup server. So let's jump to the code:
{% codeblock  host_backup.rb %}
def call(env)
  begin
    @app.call(env)
  rescue @errmatch
    unless env[:url].host == @options.host
      env[:url].host = @options.host
      retry
    end

    raise
  end
end
{% endcodeblock %}
`call` is the main method for almost every faraday middleware. Here we just trying to catch any exception from the list, and switch the url of request if the exception was raised.

You can pass exception that you want to the `@errmatch` list. Here is the list of defaults:

{% codeblock  host_backup.rb %}
def exceptions
 Array(self[:exceptions] ||= [Errno::ETIMEDOUT, 'Timeout::Error',
                             Faraday::ConnectionFailed, Faraday::Error::TimeoutError])
end
{% endcodeblock %}

In the end you can use this middleware like this:
{% codeblock lang:ruby %}
Faraday.new do |conn|
  conn.use FaradayMiddleware::HostBackup, host: "backup-service.com",
                                          exceptions: [CustomException, 'Timeout::Error']
  conn.adapter ...
end
{% endcodeblock %}

You can grab this middleware from my [repository](https://github.com/dpsk/faraday_middleware/blob/22304990ca7c439cba23fd04d0b100d2fb221f34/lib/faraday_middleware/request/host_backup.rb).