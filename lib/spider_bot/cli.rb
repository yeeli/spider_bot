# encoding: utf-8

$LOAD_PATH.unshift(File.expand_path('../..', __FILE__))
require "thor"
require 'spider_bot'
require 'daemons'

module SpiderBot
  class CLI < Thor
    desc "start", "start spider bot"
   
    method_option :daemon, 
      aliases: ["-d"], 
      desc: "daemon"

    method_option :time,
      aliases: ["-t"],
      desc: "time"

    method_option :random,
     aliases: ["-r"],
     desc: "random"

    method_option :env,
     aliases: ["-e"],
     desc: "random"

    def start
      puts "start....."
      
      if options[:env]
        ENV['RACK_ENV'] = options[:env]
      else
        ENV['RACK_ENV']= 'development'
      end
      
      require File.join(File.expand_path('../..',__FILE__), "spider_bot/load")
      
      daemon_options = {
        app_name: 'spider',
        ontop: true,
        dir: 'tmp'
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
            option_time.to_i * 60 * 60 * 60
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
            load file
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

    desc 'stop', "stop"

    def stop
      pid = File.read("tmp/spider.pid").to_i
      Process.kill(9, pid)
      File.delete("tmp/spider.pid")
    end

    desc "crawl", "crawl bot file"

    method_option :bot, 
      aliases: ["-b"], 
      desc: "read bot flle"

    method_option :dir, 
      aliases: ["-d"], 
      desc: "read dir bot flle"
    
    def crawl
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
              load file
            end
          end

          threads.each { |t| t.join }
        else
          raise "dir not found"
        end
      end
    end

    desc "url", "crawl url response"

    method_option :data,
      aliases: "-d",
      desc: "set match data"

    method_option :query,
      aliases: "-q",
      desc: "set query"

    method_option :out,
      aliases: ["-o"],
      desc: "out data file"

    def url(arg)
      data = Crawl.new(arg, options).crawl_data
      if options[:out]
        file = File.open(options[:out], "w")
        file.puts data
        file.close
      else
        puts data
      end
    end
  end
end
