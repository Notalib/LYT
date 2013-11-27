## Verification

Then(/^I see the test result in the corner$/) do
  page.should have_selector('.test-tab')
end

Then(/^I verify that tests have passed$/) do
  if page.find("#qunit>#qunit-tests>li>ol", :visible => false).visible?
    error_message = ""
    page.all("#qunit>#qunit-tests>li>ol>li.fail").each do |element|
      error_message += "Test: #{element.find("span").text}" +
        "\nError message:\n" +
        element.find("table").native.attribute("innerHTML").gsub("\n", "\n  ")
      error_message += "\n"
    end
    false.should equal(true), error_message
  end
end
