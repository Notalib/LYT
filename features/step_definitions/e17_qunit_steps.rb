## Verification

Then(/^I see the test result in the corner$/) do
  page.should have_selector('.test-tab')
end

Then(/^I verify that tests have passed$/) do
  wait_for_qunit_tests_to_complete = 20 # seconds
  if page.find("#qunit>#qunit-tests>li>ol", :visible => false,
               :wait => wait_for_qunit_tests_to_complete).visible?
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

Then(/^I verify that at least one test has failed$/) do
  wait_for_qunit_tests_to_complete = 20 # seconds
  ## The ol tag is vissible if tests have failed.
  if !page.find("#qunit>#qunit-tests>li>ol", :visible => false,
               :wait => wait_for_qunit_tests_to_complete).visible?
    false.should equal(true), "There are no qunit tests that have failed, the browser might be supported."
  end
end
