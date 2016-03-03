require 'capybara'
require 'capybara-webkit'
require 'logger'
require 'yaml'

require_relative 'tag_reader'
require_relative 'errors'

MANMENMI_ROOT = File.expand_path(File.dirname(__FILE__))
AUDIO_PREFIX = "#{MANMENMI_ROOT}/voice"
NFCPY_PREFIX = "#{MANMENMI_ROOT}/nfcpy/0.9"
LOG_PREFIX = "#{MANMENMI_ROOT}/log"

config = YAML.load(File.read("#{MANMENMI_ROOT}/config.yml"))
URL = config['url']
USERS = config['users']

logger = Logger.new("#{LOG_PREFIX}/test.log")
logger.level = Logger::INFO
logger.info('Start MANMENMIIIIII!!!!!!!')

nfc = TagReader.new

loop do
  begin
    logger.info("Start polling")
    tag = nfc.read rescue (raise Errors::NFCReadError.new("Can't read a nfc tag", __LINE__))
    # manmenmi!!!
    `mplayer #{AUDIO_PREFIX}/comeonbaby.wav 2>/dev/null`
    logger.info("Read a tag of uid:#{tag}")

    user = {}
    USERS.each do |_user|
      if _user['uid'] == tag
        user = _user
      end
    end
    raise Errors::UserRecognizeError.new("No user with uid:#{tag}", __LINE__) if user.empty?
    logger.info("Recognize a user with id:#{user['id']} name:#{user['name']}")

    session = Capybara::Session.new(:webkit)

    # login
    session.visit(URL)
    session.select(user['name'], from: '_ID')
    session.fill_in('Password', with: user['password'])
    session.click_button('ログイン')
    raise Errors::LoginError.new("Invalid password for user:#{user['name']}", __LINE__) if session.title.match(/エラー/)
    logger.info('Success login')

    # arrived or left
    login_time = Time.now
    timecard_table = session.all(:xpath, 'html/body/div/div/div/table/tbody/tr/td/table/tbody/tr/td/div/div/div/form/table/tbody/tr/td')
    arrive_cell, leave_cell = [timecard_table.at(0), timecard_table.at(1)]
    arrive_time = Time.parse(arrive_cell.text.match(/\d{2}:\d{2}/)[0])

    if login_time < arrive_time + 15 * 60 # margin 15min
      `mplayer #{AUDIO_PREFIX}/goodmorn.wav 2>/dev/null`
      logger.info("#{user['name']} already logined cybozu")
    else
      if arrive_cell.has_button?('出社')
        leave_cell.click_button('出社')
        raise Errors::UnexpectedError.new("!!! Unexpeced error !!!", __LINE__) if session.title.match(/エラー/)
        `mplayer #{AUDIO_PREFIX}/goodmorn.wav 2>/dev/null`
        logger.info("#{user['name']} arrived office")
      elsif leave_cell.has_button?('退社')
        leave_cell.click_button('退社')
        raise Errors::UnexpectedError.new("!!! Unexpeced error !!!", __LINE__) if session.title.match(/エラー/)
        `mplayer #{AUDIO_PREFIX}/goodbay.wav 2>/dev/null`
        logger.info("#{user['name']} left office")
      else
        raise Errors::UnexpectedError.new("!!! Unexpeced error !!!", __LINE__)
      end
    end
  rescue => e
    `mplayer #{AUDIO_PREFIX}/error.wav 2>/dev/null`
    logger.error(e.message)
  end
end
