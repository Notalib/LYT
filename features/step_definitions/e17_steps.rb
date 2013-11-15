When(/^I login as E17 test user$/) do
  @user = {
    login:    ENV['LYT_TEST_USER'],
    password: ENV['LYT_TEST_USER_PASSWORD']
  }
  fill_in "CPR / Brugernummer", with: @user[:login]
  fill_in "Kodeord", with: @user[:password]
  click_button "Log på"
end

When(/^I search for "(.*?)"$/) do |search_term|
  click_link "Søg"
  fill_in "Søg på titel, forfatter eller genre", :with => search_term
  click_button "søg"
end



Then(/^I see a list of books$/) do
  page.should have_selector('h1', text: "Mine bøger")
  page.should have_text("Se flere bøger")
end

