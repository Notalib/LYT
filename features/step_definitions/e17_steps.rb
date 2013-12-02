When(/^I login as E17 test user$/) do
  @user = {
    username:    ENV['LYT_TEST_USER'],
    password: ENV['LYT_TEST_USER_PASSWORD']
  }
  fill_in "CPR / Brugernummer", with: @user[:username]
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

Then(/^the book is playing(?: file at (\d+):(\d+))?$/) do |min, sec|

  find_link("Pause") # Waiting for the pause button to show
  audio = find("audio", :visible => false)
  (1..100).each do
    break if audio.native.attribute("paused") == nil
    sleep 0.1
  end
  audio.native.attribute("paused").should eq nil
  puts page.execute_script('return LYT.player.getStatus().currentTime')

  if min
    seconds = 60*min.to_i + sec.to_i
    page.execute_script('return LYT.player.getStatus().currentTime')
      .to_f.should be_between(seconds-0.5, seconds+0.5)
  end
end

When(/^I login as "(.*?)" with password "(.*?)"$/) do |user, pass|
  @user = {
    username: user,
    password: pass
  }

  fill_in "CPR / Brugernummer", with: @user[:username]
  fill_in "Kodeord", with: @user[:password]
  click_on "Log på"
end

Then(/^I see an error message "(.*?)"$/) do |msg|
  page.should have_selector('.ui-simpledialog-header',
    :wait => 5,
    :text => "Forkert brugernummer eller kodeord"
  )
end

Given(/^I play book "(.*?)"$/) do |book|
  # Find the book
  click_on "Søg"
  fill_in "Søg på titel, forfatter eller genre", :with => book
  click_on "søg"
  find(".book-play-link:nth-of-type(1)").click
  click_on "Afspil"

  # Wait for it to load
  page.should have_selector('.ui-loader', :wait => 5)
  page.should_not have_selector('.ui-loader', :wait => 60)

  script = <<EOF
    return LYT.player.book.nccDocument.sections
      .map(function(sec) { return sec.title })
EOF

  @book = {
    sections: page.execute_script(script)
  }
end

And(/^I wait for the next section to start$/) do
  # Fixture-specific implementation for sections shorter than 8-9 seconds
  page.should have_text(@book[:sections][1], :wait => 10)
end

Given(/^I play the book for the first time$/) do
  # Delete lastmark, so we can fool the player
  page.execute_script('LYT.player.book.lastmark = null')

  first = @book[:sections][0]
  # Pick the first section from the TOC
  click_on "Indholdsfortegnelse"
  click_on first

  # Wait for it to load
  page.should have_text(first)
end

When(/^I wait for (\d+) seconds$/) do |seconds|
  sleep seconds.to_i
end
