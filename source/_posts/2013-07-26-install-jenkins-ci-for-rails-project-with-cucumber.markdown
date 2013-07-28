---
layout: post
title: "Install Jenkins CI for Rails project with Cucumber"
date: 2013-07-26 18:34
comments: true
keywords: Rails, Ruby, CI, Continious Integration, Jenkins, Hudson, Cucumber, specs, Rails with Cucumber, Ubutnu, RSpec
categories: [Rails, Ruby, CI, Jenkins, Cucumber, Ubnutu, RSpec]
---

## Jenkins

{% img right /images/posts/jenkins_logo.png 'Jenkins logo' %}
This is a short guide on how to setup Jenkins(Hudson) for Rails project with cucumber features. The steps are described for Ubuntu machine. First of all - what is Jenkins?

Jenkins is an award-winning application that monitors executions of repeated jobs, such as building a software project or jobs run by cron. Among those things, current Jenkins focuses on the following two jobs:

  - Building/testing software projects continuously, just like CruiseControl or DamageControl. In a nutshell, Jenkins provides an easy-to-use so-called continuous integration system, making it easier for developers to integrate changes to the project, and making it easier for users to obtain a fresh build. The automated, continuous build increases the productivity.
  - Monitoring executions of externally-run jobs, such as cron jobs and procmail jobs, even those that are run on a remote machine. For example, with cron, all you receive is regular e-mails that capture the output, and it is up to you to look at them diligently and notice when it broke. Jenkins keeps those outputs and makes it easy for you to notice when something is wrong.

Let's install Jenkins with following commands:
<!--more-->

```bash
  wget -q -O - http://pkg.jenkins-ci.org/debian/jenkins-ci.org.key | sudo apt-key add -
  sudo sh -c 'echo deb http://pkg.jenkins-ci.org/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
  sudo apt-get update
  sudo apt-get install jenkins
```

From this point you can start jenkins like this:
```
sudo /etc/init.d/jenkins start
```
## NGINX
Now we need to configure nginx for jenkins, the most basic setup will look like this:

```
upstream jenkins {
  server 127.0.0.1:8080;
}

server {
  listen 111.111.111.111:80;
  server_name jenkins.project_name.com *.jenkins.project_name.com;

  try_files $uri @jenkins;

  location @jenkins {
      proxy_pass http://jenkins;
      proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
      proxy_set_header Host $http_host;
      proxy_redirect off;
  }
}
```

So now jenkins web interface is up and running at jenkins.project_name.com

## Jenkins User
Jenkins using ``jenkins`` ubuntu user by default. We should add the pair of ssh keys to him, as well as install ruby. For this purposes login as jenkins
``sudo su jenkins``. ``ssh-keygen -t rsa`` to generate ssh keys. Install ruby with rvm or your ruby version manager of choice. Also we should add name and email to git for jenkins. So the list of commands will be following:

```
sudo su jenkins
ssh-keygen -t rsa
\curl -L https://get.rvm.io | bash -s stable --ruby
echo "source $HOME/.rvm/scripts/rvm" >> ~/.bash_profile
source ~/.bash_profile
rvm install 1.9.3
git config --global user.email "jenkins@example.com"
git config --global user.name "Jenkins Hudson"
```

## Jenkins Plugins

Now let's install some useful plugins for Jenkins. Go to the  *Manage Jenkins -> Manage Plugins* and check following plugins:

 * Git Client Plugin
 * GitHub Plugin
 * Ruby Plugin
 * Rake plugin
 * Cucumber plugin

## Add project to Jenkins

Now we a ready to add our project to Jenkins. Go to the *New Job -> Free-style* Navigate to ``Source Code Management`` menu and choose Git, enter your git repository address and specify the branch.

{% img /images/posts/hudson_git.png 'Jenkins Git options' 'Jenkins Git options' %}

Now we only need to specify commands for building our project. Specify "Execute shell script" and add following commands, you may want to change them for your needs:

```
#!/bin/bash -x
source ~/.bash_profile
rvm use 1.9.3
bundle install
cp config/database.yml.example database.yml
rake db:test:prepare RAILS_ENV=test
cucumber
```

You also may want to add some notifications, for my project i'm using hipchat notification, but the most easiest solution to setup is email notifications. You will need to add SMTP settings in the *Manage Jenkins -> System Configurations -> E-mail Notification*. After that just specify emails in the project settings.

If you want to run your rspec tests instead of cucumber, or run all together just change your build commands.

That's all, you are ready to go!