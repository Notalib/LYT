Feature: An anonymous user navigates LYT.
  As a E17 member I can navigate to LYT test page and runs tests

  Background: I log in using member login
    Given I visit "/"
    And I login as E17 test user
    And I wait for hourglass to appear and disappear
    Given I visit "/#test"

  Scenario: I run the internal tests
    When I click "Kør tests"
    Then I see the test result in the corner
    And I click "Unit test"
    And I verify that tests have passed
