# encoding: utf-8
When(/^I visit "(.*?)"$/) do |url|
  raise "page must start with '/'" unless url[0] == ?/
  visit "#{url}"
  page.should have_css("body")
  page.execute_script('window.onerror=function(msg){ $("body").attr("JSError",msg); };')
end


When(/^I click "(.*?)"$/) do |link_name|
  begin
    click_on link_name, :wait => 2
  rescue Capybara::ElementNotFound
    find(:xpath, "//a[@title='#{link_name}']").click
  end
end

#Verifications:

Then(/^I see a link "(.*?)" to "(.*?)"$/) do |text, url|
  page.should have_link(text, href: url)
end

Then(/^I see "(.*?)"$/) do |text|
  page.should have_text(text)
end

Given(/^I close the tab$/) do
    pending # express the regexp above with the code you wish you had
end

Given(/^I open a tab$/) do
    pending # express the regexp above with the code you wish you had
end
