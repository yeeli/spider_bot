# encoding: utf-8

$LOAD_PATH.unshift(File.expand_path('../..', __FILE__))
require "thor"
require 'spider_bot'
require 'daemons'

module SpiderBot
  class CLI < Thor
    desc "new", "create new spider project"
 
    def new(name)
    end

    desc "start", "start spider bot"
    def start
      Daemons.run_proc('Spider') do
        loop do
          puts "1"
          sleep(1*60*5)
        end
      end
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
               sleep(Random.new.rand(10))
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
