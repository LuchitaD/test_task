require 'watir'
require 'nokogiri'
require_relative 'transaction'

class Moldindconbank
  attr_reader :browser
  def initialize
    @browser = Watir::Browser.new(:chrome)
  end

  def collect_data
    log_in
    sleep(2)
    result = {accounts: parse_accounts}
    log_out

    result
  end

  private

  def log_in
    browser.goto("https://wb.micb.md/")
    puts "Write your Username: "
    browser.text_field(class: "username").set(gets.chomp)
    puts "Write your Password: "
    browser.text_field(id: "password").set(gets.chomp)
    browser.button(class: "wb-button").click
    raise "Invalid Username or Password" if browser.div(class: %w(page-message error)).present? 
  end

  def parse_accounts
    accounts_div = browser.divs(class: %w(contract status-active))

    accounts_div.map do |element|
      Watir::Wait.until { element.div(class: "contract-cards").a.present? }
      element.div(class: "contract-cards").a.click

      go_to_card_info
      account_html = Nokogiri::HTML(browser.div(id: "contract-information").html)
      result = parse_account(account_html)

      go_to_transaction_info
      result[:transactions] = parse_transactions

      browser.li(class: %w(new_cards_accounts-menu-item active)).a.click

      result
    end
  end

  def parse_account(html)
    {
      name: html.css('tr')[-3].css('td')[1].text,
      balance: html.css('tr')[-1].css('td')[1].css('span')[0].text.gsub(",",".").to_f,
      currency: html.css('tr')[-1].css('td')[1].css('span')[1].text,
      description: html.css('tr')[3].css('td')[1].text.gsub("2. De baza - ", "")
    }
  end

  def go_to_card_info
    browser.ul(class: %w(ui-tabs-nav ui-helper-reset ui-helper-clearfix ui-widget-header ui-corner-all)).lis[1].click
  end

  def go_to_transaction_info
    browser.link(href: "#contract-history").click
    browser.text_field(class: %w(filter-date from maxDateToday hasDatepicker)).click
    Watir::Wait.until { browser.link(class: %w(ui-datepicker-prev ui-corner-all)).present? }
    browser.link(class: %w(ui-datepicker-prev ui-corner-all)).click
    sleep(2)
    Watir::Wait.until { browser.link(class: "ui-state-default").present? }
    browser.link(class: "ui-state-default").click
  end

  def parse_transactions
    Watir::Wait.until { browser.div(class: "operations").li.present? }
    transaction_list = browser.div(class: "operations").lis

    transaction_list.map do |li|
      Watir::Wait.until { li.link.present? }
      li.link.click
      transaction_body = Nokogiri::HTML.parse(browser.div(class: "operation-details-body").html)
      transaction_header = Nokogiri::HTML.parse(browser.div(class: "operation-details-header").html)

      browser.send_keys :escape

      parse_transaction(transaction_body, transaction_header).to_hash
    end
  end

  def parse_transaction(transaction_body, transaction_header)
    date = transaction_body.css('.operation-details-body').css('.details-section')[0].css('.value')[0].text
    description = transaction_header.css('.operation-details-header').text.gsub("  ", "")
    amount = transaction_body.css('.details-section.amounts').css('.value')[0].text.split[0].gsub(",", ".").to_f

    Transaction.new(date, description, amount)
  end

  def log_out
    browser.span(class: "logout-link-wrapper").click
  end
end

if __FILE__ == $0
  require 'json'   
  require 'pry'

  webbanking = Moldindconbank.new
  puts JSON.pretty_generate(webbanking.collect_data)
end
