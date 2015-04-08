# SpiderBot

一个简单的机器爬虫

## SpiderBot 安装

将下列文字添加到你程序中的Gemfile里

```
gem 'spider_bot'
```

并执行:

    $ bundle

或者直接通过命令安装:

    $ gem install spider_bot

## SpiderBot 文件

#### 文件格式

1.单站单页爬取， 返回html文本

```
SpiderBot.crawl("http://example.com", #{origin_options})
```

2.单站多页爬取

```
SpiderBot.crawl("#{url}", data: Proce.new{ |data| data }, since: Proce.new{ |data| data }) do

  paginate do
    option :type, :json
    option :path, '#{path}'
    
    # 翻页页码设置
    option :start, 0
    option :add, 10
    option :expire, 100
    option :sleep, 6
     
    # 翻页后获取信息设置
    option :data, Proc.new{ |data| data }
    option :since, Proc.new{ |since| since }
    
    option query, {page: "%{page}", since_id: %{since}}
  end
  
  crawl_data do |data|
    # 解析爬取的数据...
  end
end
```

3.多站，多页内容爬取， 可以配合Rails或者padrino进行任务爬去

```
class Mybot < SpiderBot::Base
  origin "#{url}", data: Proc.new{ |data| data }, since: Proce.new{ |since| since }

  paginate do
    option :type, :json
    option :path, '#{path}'
    
    # 翻页页码设置
    option :start, 0
    option :add, 10
    option :expire, 100
    option :sleep, 6
     
    # 翻页后获取信息设置
    option :data, Proc.new{ |data| data }
    option :since, Proc.new{ |since| since }
    
    option query, {page: "%{page}", since_id: %{since}}
  end
  
  crawl_data do |data|
    # 解析爬取的数据...
  end
end
```

####初始页面参数设置 origin_options

* path
* type
* headers
* query 
* data 获取初始页面数据
* since 获取初始页码数据最后一条参数，用户翻页

####翻页参数设置

1.翻页后文本设置

* paginate_type 翻页后类型[:html, :json, :xml]
* paginate_path 翻页后的Path
* paginate_query 翻页后的参数设置 {page: "%{page}", since: "%{since}"}


2.翻页设置

* paginate_start #翻页起始页， 默认为0
* paginate_add #翻页增加数， 默认为 1
* paginate_expire #翻页总结数， 默认为30
* paginate_sleep #翻页休息数， 默认为 0

3.翻页信息获取

* paginate_data 获取翻页后的数据, 不填写，默认为origin data
* paginate_since 获取翻页后最后数据， 不填写， 默认为 origin_since


## SpiderBot 命令

* spider url #直接通过命令爬取, 返回html文本
  - -q query， 设置Query
  - -d data， 爬取数据
  - -o out，输出到文件

* spider crawl #运行bot文件
  - -b bot, 运行单一bot文件
  - -d dir, 运行指定目录里的bot文件

* spider start #运行爬取服务
  - -d daemon, 后台运行
  - -t time, #设置爬取时间间隔， 默认为10
  - -r random #将爬取时间间隔， 设置为时间下一个随机数， 默认为10的随机数
  - -e env #设置Sipder运行环境， 如果配合Rails或者Padrino， 获取指定运行环境

* spider stop #停止爬取服务



