# encoding: utf-8

$LOAD_PATH.unshift(File.expand_path('../..', __FILE__))
require "thor"
require 'spider_bot'
require 'daemons'

BOTCONSOLE = true

module SpiderBot
  class CLI < Thor
    desc "url", "Crawl url"

    method_option :query,
      aliases: "-q",
      desc: "Set url query"

    method_option :data,
      aliases: "-d",
      desc: "Match html data"

    method_option :out,
      aliases: ["-o"],
      desc: "Write to file"

    def url(arg)
      data = Crawl.new(arg, options).crawl_data
      return File.open(options[:out], "w"){ file.puts data } if options[:out]
      return puts data 
    end

    desc "crawl", "Run spider bot file"

    method_option :bot, 
      aliases: ["-b"], 
      desc: "Read bot flle"

    method_option :dir, 
      aliases: ["-d"], 
      desc: "Read bot directory"

    method_option :expire, 
      aliases: ["-p"], 
      desc: "Read data expired number"
    
    def crawl
      $expire_num = options[:expire].to_i if options[:expire]

      require File.join(File.expand_path('../..',__FILE__), "spider_bot/load")

      if options[:bot]
        bot_file = File.expand_path(options[:bot]) 
        
        if File.exists?(bot_file)
          load bot_file 
        else
          raise "file not found"
        end
      end
    

      if options[:dir]
        bot_dir = File.expand_path(options[:dir]) 

        if Dir.exists?(bot_dir)
          threads = []

          Dir.glob("#{bot_dir}/*_bot.rb").each do |file|
            threads << Thread.new do
              begin
                SpiderBot.logger.info "loading bot file with #{file}."
                load file
              rescue Exception => e
                SpiderBot.logger.error "has errors with loading bot file #{ file }"
                SpiderBot.logger.error e.to_s
              end
            end
          end

          threads.each { |t| t.join }
        else
          raise "dir not found"
        end
      end
    end


    desc "start", "Run spider bot service"
   
    method_option :daemon, 
      aliases: ["-d"], 
      desc: "Run spider bot service in background"

    method_option :time,
      aliases: ["-t"],
      desc: "Set crawl interval"

    method_option :random,
     aliases: ["-r"],
     desc: "Set crawl interval to random "

    method_option :env,
     aliases: ["-e"],
     desc: "set spider service environment"

    method_option :expire, 
      aliases: ["-p"], 
      desc: "Read data expired page_number"

    def start
      puts "start....."
      
      $expire_num = options[:expire].to_i if options[:expire]
      
      if options[:env]
        ENV['RACK_ENV'] = options[:env]
      else
        ENV['RACK_ENV']= 'development'
      end
      
      require File.join(File.expand_path('../..',__FILE__), "spider_bot/load")
      
      daemon_options = {
        app_name: 'spider',
        ontop: true,
        dir: 'tmp',
      }

      sleep_time = 10
      
      if options[:daemon]
        daemon_options[:ontop] = false 
      else
        puts "press ctrl-c exit"
      end

      stop if File.exists?("tmp/spider.pid")

      if option_time = options[:time]
        parse_time = option_time.match(/[d|h|m]/)
        sleep_time = if parse_time
          case parse_time[0]
          when "d"
            option_time.to_i * 60 * 60 * 24
          when "h"
            option_time.to_i * 60 * 60
          when "m"
            option_time.to_i * 60
          end
        else
          option_time.to_i
        end
      end

      Daemons.daemonize(daemon_options)
      
      loop do
        threads = []
        
        BOTDIR.each do |file|
          threads << Thread.new do
            begin
              SpiderBot.logger.info "loading bot file with #{file}."
              load file
            rescue Exception => e
              SpiderBot.logger.error "has errors with loading bot file #{ file }"
              SpiderBot.logger.error e.to_s
            end
            sleep(10)
          end
        end

        threads.each { |t| t.join }
        
        if options[:random]
          random_time = Random.new.rand(sleep_time)
          sleep(random_time.to_i)
        else
          sleep(sleep_time.to_i)
        end
      end
    end

    desc 'stop', "Stop spider bot service"

    def stop
      pid = File.read("tmp/spider.pid").to_i
      Process.kill(9, pid)
      File.delete("tmp/spider.pid")
    end
  end
end
