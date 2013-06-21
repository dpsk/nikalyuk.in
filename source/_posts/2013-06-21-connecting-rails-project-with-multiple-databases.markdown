---
layout: post
title: "Connecting rails project with multiple databases"
date: 2013-06-21 16:22
comments: true
categories: [Rails, Ruby, Databases, MySQL]
---

Today on one of my Rails project i was in need to implement support ticketing system. Database for this system was already working for a good amount of time, so i was forced to use it as a source. I want to share my experience, first of all we should create base class in the ``/app/models/``, so we can inherit models, that will use external database as source, from it.
{% codeblock  app/models/support_base.rb %}
class SupportBase < ActiveRecord::Base

  self.abstract_class = true

  databases = YAML::load(IO.read('config/database_support.yml'))
  establish_connection(databases[Rails.env])

end
{% endcodeblock %}
<!--more-->
The ``self.abstract_class = true`` tells Active Record to not look up for a table, since this calss is only used to add customm settings we don't need any database table for it.

After that we need to create a databases.rake file that will wrap database tasks for external database.

{% codeblock lang:ruby lib/tasks/databases.rake %}
namespace :support do

  desc "Configure the variables that rails need in order to look up for the db
    configuration in a different folder"
  task :set_custom_db_config_paths do
    # This is the minimum required to tell rails to use a different location
    # for all the files related to the database.
    ENV['SCHEMA'] = 'db_support/schema.rb'
    Rails.application.config.paths['db'] = ['db_support']
    Rails.application.config.paths['db/migrate'] = ['db_support/migrate']
    Rails.application.config.paths['db/seeds'] = ['db_support/seeds.rb']
    Rails.application.config.paths['config/database'] = ['config/database_support.yml']
  end

  namespace :db do
    task :drop => :set_custom_db_config_paths do
      Rake::Task["db:drop"].invoke
    end

    task :create => :set_custom_db_config_paths do
      Rake::Task["db:create"].invoke
    end

    task :migrate => :set_custom_db_config_paths do
      Rake::Task["db:migrate"].invoke
    end

    task :rollback => :set_custom_db_config_paths do
      Rake::Task["db:rollback"].invoke
    end

    task :seed => :set_custom_db_config_paths do
      Rake::Task["db:seed"].invoke
    end
    namespace :test do
      task :prepare => :set_custom_db_config_paths do
        Rake::Task["db:test:prepare"].invoke
      end
    end

    task :version => :set_custom_db_config_paths do
      Rake::Task["db:version"].invoke
    end
  end
end
{% endcodeblock %}

We basically get all the standart rake database tasks, but wrap them in the support namespace and redefine application paths, so rake will run this commands on the external database.

## Now, let's create files that we mention in this task:
  - ``db_support`` folder in the root of application
  - ``db_support/migrate`` folder for migrations
  - ``db_support/seeds.rb`` file with the seeds for support database
  - ``config/database_support.yml`` file with the settings for database connection

Here is an example of `database_support.yml`:

{% codeblock config/database_support.yml %}
development:
  adapter: mysql2
  database: support_development
  pool: 5
  username: user
  password: password

test:
  adapter: mysql2
  database: support_test
  pool: 5
  username: user
  password: password

production:
  adapter: mysql2
  database: partners_external
  pool: 5
  ip: 192.168.1.1
  port: 3306
  username: external_username
  password: external_password

{% endcodeblock %}

The key is that you still want to use local database in the development and for the tests.

At this point we are pretty much done, now we can use commands like ``bundle exec rake support:db:create`` to create development and test database. We also still able to use ``bundle exec rake db:migrate`` for the default database.

This solution is pretty extensible, so it wouldn't be hard to add as much databases as you need.