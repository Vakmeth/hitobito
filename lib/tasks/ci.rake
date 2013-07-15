desc "Runs the tasks for a commit build"
task :ci => ['log:clear',
             'wagon:bundle:update',
             'db:migrate',
             'ci:setup:rspec',
             'spec:requests', # run request specs first to get coverage from spec
             'spec',
             'wagon:test']

namespace :ci do
  desc "Runs the tasks for a nightly build"
  task :nightly => ['log:clear',
                    'wagon:bundle:update',
                    'db:migrate',
                    'erd',
                    'ci:setup:rspec',
                    'spec:requests', # run request specs first to get coverage from spec
                    'spec',
                    'wagon:test',
                    'brakeman',
                    #'qa' # stack level too deep on jenkins :(
                    ]
end

desc "Add column annotations to active records"
task :annotate do
  sh 'annotate -p before'
end

desc "Run brakeman"
task :brakeman do
  FileUtils.rm_f('brakeman-output.tabs')
  # some files seem to cause brakeman to hang. ignore them
  ignores = %w(app/views/people_filters/_form.html.haml
               app/views/csv_imports/define_mapping.html.haml
               app/models/mailing_list.rb)
  begin
    Timeout.timeout(300) do
      sh "brakeman -o brakeman-output.tabs --skip-files #{ignores.join(',')} --no-progress"
    end
  rescue Timeout::Error => e
    puts "\nBrakeman took too long. Aborting."
  end
end

desc "Run quality analysis"
task :qa do
  # do not fail if we find issues
  sh 'rails_best_practices -x config,db -f html --vendor .' rescue nil
  true
end

namespace :erd do
  task :options => :customize
  task :customize do
    ENV['attributes']  ||= 'content,inheritance,foreign_keys,timestamps'
    ENV['indirect']    ||= 'false'
    ENV['orientation'] ||= 'vertical'
    ENV['notation']    ||= 'uml'
    ENV['filename']    ||= 'doc/models'
    ENV['filetype']    ||= 'png'
  end
end

desc "Load the mysql database configuration for the following tasks"
task :mysql do
  ENV['RAILS_DB_ADAPTER']  = 'mysql2'
  ENV['RAILS_DB_NAME']     = 'hitobito_test'
  ENV['RAILS_DB_PASSWORD'] = 'root'
  ENV['RAILS_DB_SOCKET']   = '/var/run/mysqld/mysqld.sock'
end
