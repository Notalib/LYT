# encoding: utf-8
When(/^I visit '(.*?)'$/) do |url|
  raise "page must start with '/'" unless url[0] == ?/
  visit "#{url}"
end


When(/^I click "(.*?)"$/) do |link_name|
  click_link link_name
end



#Verifications:

Then(/^I see a link "(.*?)" to "(.*?)"$/) do |text, url|
  page.should have_link(text, href: url)
end