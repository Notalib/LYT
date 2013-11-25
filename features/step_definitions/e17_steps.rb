When(/^I login as E17 test user$/) do
  @user = {
    login:    ENV['LYT_TEST_USER'],
    password: ENV['LYT_TEST_USER_PASSWORD']
  }
  fill_in "CPR / Brugernummer", with: @user[:login]
  fill_in "Kodeord", with: @user[:password]
  click_on "Log på"
end

When(/^I wait for the login screen$/) do
  page.should have_selector('h1', text: "Log ind")
end

When(/I wait for hourglass to appear and disappear/) do
  ##This Step is really stupid... It is a workaround for the fact that
  ##LYT displays elements that do not work at the time they are shown.
  page.should have_selector('.ui-loader')
  page.should_not have_selector('.ui-loader')
end

When(/^I search for "(.*?)"$/) do |search_term|
  click_on "Søg"
  fill_in "Søg på titel, forfatter eller genre", :with => search_term
  click_on "søg"
end



Then(/^I see a list of books$/) do
  page.should have_selector('h1', text: "Mine bøger")
  page.should have_text("Se flere bøger")
end

