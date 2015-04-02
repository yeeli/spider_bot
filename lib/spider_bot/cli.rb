# encoding: utf-8
require "thor"

module SpiderBot
  class CLI < Thor
   desc "new", "create new spider project"

   def new(name)
   end

    desc "start", "start spider bot"
    def start
      p "start"
    end

    desc "crawl", "crawl bot file"

    method_option :bot, 
      aliases: ["-b"], 
      desc: "read bot flle"

    method_option :out,
      aliases: ["-o"],
      desc: "out data file"
    
    def crawl
    end
  end
end
