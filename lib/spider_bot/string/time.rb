#coding: utf-8

DATE_CONFIG = YAML.load_file(File.expand_path("../date.yml", __FILE__))

class String
  
  # Parse content to local time
  #
  # @param [String] zone time zone with site
  def parse_time(zone = nil)
    Time.zone = zone.nil? ? "UTC" : zone

    @time_config = DATE_CONFIG["date"]["time"]
    @month_config = DATE_CONFIG["date"]["month"]
    @other_config = DATE_CONFIG["date"]["other"]
    @time_str = @time_config.values.join("|")

    @time_regex = %r"\d+[\s|\S]*(?:#{@time_str})\s*(?:#{@other_config["ago"]})"
    @today_regex = %r"#{@other_config["today"]}\s*\d{1,2}:\d{1,2}"

    case self 
    when @time_regex
      parse_date_ago
    when @today_regex 
      parse_today
    else
      parse_date
    end

  end

  private

  # Parse content if has keyword mean 'ago' 
  def parse_date_ago
    now = Time.zone.now 
    regex_text = self.match(@time_regex)[0]
    @time = case regex_text
            when %r"#{@time_config["year"]}"
              now.years_ago regex_text.match(/\d+/)[0].to_i
            when %r"#{@time_config["month"]}"
              now.months_ago regex_text.match(/\d+/)[0].to_i
            when %r"#{@time_config["week"]}"
              now.ago regex_text.match(/\d+/)[0].to_i * 60 * 60 * 24 * 7
            when %r"#{@time_config["day"]}"
              now.ago regex_text.match(/\d+/)[0].to_i * 60 * 60 * 24
            when %r"#{@time_config["hour"]}"
              now.ago regex_text.match(/\d+/)[0].to_i * 60 * 60
            when %r"#{@time_config["min"]}"
              now.ago regex_text.match(/\d+/)[0].to_i * 60 
            when %r"#{@time_config["second"]}"
              now.ago regex_text.match(/\d+/)[0].to_i
            else
              raise "get date errors"
            end
  end

  # Parse content if has keyword mean 'today'
  def parse_today
    now = Time.zone.now 
    regex_text = self.match(/\d{1,2}\s*:\s*\d{1,2}:*\d{0,2}/)[0]
    time_str = now.to_date.to_s + " " + regex_text
    Time.zone.parse(time_str)
  end

  def parse_date
    date_regex1 = %r"(\d{4})[^\d|:]{1,2}(\d{1,2})[^\d|:]{1,2}(\d{1,2})"
    date_regex2 = %r"(\d{1,2})[^\d|:]{1,2}(\d{1,2})[^\d|:]{1,2}(\d{4})"
    date_regex3 = %r"([\w|\W]+)[^\d|\w]{1,2}(\d{1,2})[^\d|:]*(\d{4})"
    time = self.match %r"\d{1,2}\s*:\d{1,2}\s*:*\d{0,2}(?:#{@other_config["am"]}|#{@other_config["pm"]})*"
      time = time[0].gsub(%r"#{@other_config["am"]}","am").gsub(%r"#{@other_config["pm"]}","pm") if time

    case self
    when date_regex1

      date_text = self.match date_regex1

      Time.zone.parse "#{date_text[1]}-#{date_text[2]}-#{date_text[3]} #{time}"
    when date_regex2
      date_text = self.match date_regex2
      Time.zone.parse("#{date_text[3]}-#{date_text[1]}-#{date_text[2]} #{time}")
    when date_regex3
      date_text = self.match date_regex3
      month = case date_text[1].downcase
              when %r"#{@month_config["jan"]}"
                1
              when %r"#{@month_config["feb"]}"
                2
              when %r"#{@month_config["mar"]}"
                3
              when %r"#{@month_config["apr"]}"
                4
              when %r"#{@month_config["may"]}"
                5
              when %r"#{@month_config["jun"]}"
                6
              when %r"#{@month_config["jul"]}"
                7
              when %r"#{@month_config["aug"]}"
                8
              when %r"#{@month_config["sep"]}"
                9
              when %r"#{@month_config["oct"]}"
                10
              when %r"#{@month_config["nov"]}"
                11
              when %r"#{@month_config["dec"]}"
                12
              end
      Time.zone.parse "#{date_text[3]}-#{month}-#{date_text[2]} #{time}"
    else
      Time.zone.parse(self)
    end
  end
end

