# encoding: utf-8
When(/^I visit '(.*?)'$/) do |url|
  raise "page must start with '/'" unless url[0] == ?/
  visit "#{url}"
end


When(/^I click "(.*?)"$/) do |link_name|
  click_on link_name
end

When(/^I wait for the login screen$/) do
  page.title.should have_text("Log ind")
end


#Verifications:

Then(/^I see a link "(.*?)" to "(.*?)"$/) do |text, url|
  page.should have_link(text, href: url)
end

Then(/^I see "(.*?)"$/) do |text|
  page.should have_text(text)
end
