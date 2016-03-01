require 'mechanize'
require 'logger'
require 'yaml'

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

loop do
  begin
    logger.info("Start polling")
    cmd_out = `python #{NFCPY_PREFIX}/examples/tagtool.py show 2>/dev/null`
    raise "L:#{__LINE__}# Can't read a nfc tag" if cmd_out.empty?
    # manmenmi!!!
    `mplayer #{AUDIO_PREFIX}/comeonbaby.wav 2>/dev/null`
    tag = cmd_out.match(/IDm?=([\da-fA-F]*)/)[1]
    logger.info("Read a tag of uid:#{tag}")

    user = {}
    USERS.each do |_user|
      if _user['uid'] == tag
        user = _user
      end
    end
    raise "L:#{__LINE__}# No user with uid:#{tag}" if user.empty?
    logger.info("Recognize a user with id:#{user['id']} name:#{user['name']}")

    agent = Mechanize.new

    # login
    login_form = agent.get(URL).form
    login_form._ID = user['id']
    login_form.Password = user['password']
    user_page = agent.submit(login_form)
    raise "L:#{__LINE__}# invalid password for user:#{user['name']}" if user_page.title.match(/エラー/)
    logger.info('Success login')

    # arrived or left
    timecard_form = user_page.forms_with(method: 'POST')[2]
    arrive_timetable = (user_page / 'html/body/div/div/table/tr/td/table/tr/#cb7-portal-left/#cb7-portlet-frame-41/#cb7-portlet-41/#cb7-portlet-body-41/form/table/tr/td[1]')[0]
    arrive_time = Time.parse(arrive_timetable.children[2].text)
    login_time = Time.now

    if login_time < arrive_time + 15 * 60 # margin 15min
      `mplayer #{AUDIO_PREFIX}/goodmorn.wav 2>/dev/null`
      logger.info("#{user['name']} already logined cybozu")
    else
      if timecard_form.button_with(value: '出社')
        `mplayer #{AUDIO_PREFIX}/goodmorn.wav 2>/dev/null`
        timecard_form.click_button
        logger.info("#{user['name']} arrived office")
      elsif timecard_form.button_with(value: '退社')
        `mplayer #{AUDIO_PREFIX}/goodbay.wav 2>/dev/null`
        timecard_form.click_button
        logger.info("#{user['name']} left office")
      else
        raise "L:#{__LINE__}# !!! Unexpeced error !!!"
      end
    end
  rescue => e
    `mplayer #{AUDIO_PREFIX}/error.wav 2>/dev/null`
    logger.error(e.message)
  end
end
