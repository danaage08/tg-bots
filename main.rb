require 'notion-ruby-client'
require 'telegram/bot'
require 'rufus-scheduler'

TOKEN_TG = '6773479267:AAFMKib2KgXLWzcJOJNWCM4rAfWWjplzzBg'
NOTION_TOKEN = 'secret_Y0bzcZHsWYb2mbKJbv77EPUI5haF4brzYaG1Hy5eSN9'
DATABASE_ID = '3627e63a-f2b5-47dd-9a44-57e8b1d43453'

client = Notion::Client.new(token: NOTION_TOKEN)

def check_day(client, bot, id)
  client.database_query(database_id: DATABASE_ID) do |page|
    list_element = page.results

    for i in list_element
      title_property = i.properties["Name"]
      title_text = title_property["title"][0]["text"]["content"]
      puts "Текст: #{title_text}"

      date_property = i.properties["Date"]

      date_str = date_property.to_s
      date_regex = /start=(\d{4}-\d{2}-\d{2})/
      match = date_regex.match(date_str)
      extracted_date = match[1]
      puts "Дата: #{extracted_date}"
      puts

      if Date.today.to_s == extracted_date
        send_message(title_text, bot, id)
      end
    end
  end
end

def send_message(title_text, bot, id)
  bot.api.send_message(chat_id: id, text: "Сегодня важный день: #{title_text}")
end

def schedule_daily_check(scheduler, client, bot, tg_id)
  scheduler.cron '0 10 * * *' do
    puts "Выполняем проверку изменений в Notion базе данных..."
    check_day(client, bot, tg_id)
  end
end

Telegram::Bot::Client.run(TOKEN_TG) do |bot|
  tg_id = 6192045821
  bot.listen do |message|
    if message.text == "/start"
      # Установка часового пояса до инициализации объекта Rufus::Scheduler
      ENV['TZ'] = 'Europe/Moscow'
      puts('Бот начал свою работу')

      scheduler = Rufus::Scheduler.new

      schedule_daily_check(scheduler, client, bot, tg_id)

      scheduler.join
    end
  end
end