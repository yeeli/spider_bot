# SpiderBot

一个简单的机器爬虫

## 安装

将下列文字添加到你程序中的Gemfile里

```ruby
gem 'spider_bot'
```

并执行:

    $ bundle

或者直接通过命令安装:

    $ gem install spider_bot

## 使用

### 文件调用

```ruby
require 'spider_bot'

SpiderBot.crawl("http:://example.com/funny")

```



crawl_options 参数

* path
* type
* headers
* query 
* data 需要爬去的数据
* since 需要获取的最后一条参数


### 执行独立文件

spider -bot name_bot.rb -out data.txt

###独立程序中使用

初始化爬虫程序
	
	$ spider new projectName

然后自动生成

```
  projectNmae
    |— app
      |- models #数据库文件
         |- model.rb
      |- bots  #爬虫文件
         |- site_bot.rb
    |- config
      |- database.yml #数据文件
      |- splider.yml #爬虫程序的配置文件
    |- log
    |- db
    
```

通过命令生成爬虫文件

splider bot #{bot_name} 

最后执行

	$ cd ProjectName
	$ spider start

### 在Rails中使用

添加爬虫文件

	$ rails new bot #{bot_name}
	
当执行上述命令后， 会自动在rails程序中的app目录下生成bots目录。
  
```
Rails Project
  |- app
    |- bots #爬虫程序
  |- config
    |- splider.yml #爬虫程序的配置
```

然后在rails应用中执行

	$ bundle exec splider start

