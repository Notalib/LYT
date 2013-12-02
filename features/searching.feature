Feature: A guest user searches the archive

  Background: I am a guest user
    Given I visit "/"
    And I wait for the login screen
    And I click "Prøv E17 Direkte uden login"
    And I wait for hourglass to appear and disappear

  Scenario: I search for Harry Potter books
    When I search for "Harry Potter"
    Then I see "Harry Potter og De Vises Sten"
    And I see "Harry Potter og Hemmelighedernes Kammer"
    And I see "Harry Potter og fangen fra Azkaban"
    And I see "Harry Potter og Flammernes Pokal"
    And I see "Harry Potter og Fønixordenen"
    And I see "Harry Potter og halvblodsprinsen"
    And I see "Harry Potter og dødsregalierne"

