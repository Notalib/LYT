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
  page.should have_selector('.ui-loader', :wait => 5)
  page.should_not have_selector('.ui-loader', :wait => 60)
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


Then(/^the book is playing file at (\d+):(\d+)$/) do |min, sec|
  seconds = 60*min.to_i + sec.to_i

  find_link("Pause") # Waiting for the pause button to show
  audio = find("audio", :visible => false)
  (1..100).each do
    break if audio.native.attribute("paused") == nil
    sleep 0.1
  end
  puts page.execute_script('return LYT.player.getStatus().currentTime')
  page.execute_script('return LYT.player.getStatus().currentTime').to_f.should be_between(seconds-0.5, seconds+0.5)
end
