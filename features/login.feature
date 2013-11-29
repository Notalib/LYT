Feature: Various login tests
  Tries to login with various combinations of user/pass
  Some fail, some don't.

  Background: I am an anonymous user.
    Given I visit "/"
    And I wait for the login screen

  Scenario: I login with correct username and password
    When I login as "66845" with password "Nota1234"
    Then I see a list of books

  Scenario: I login with correct username but incorrect password
    When I login as "66845" with password "nota4321"
    Then I see an error message "Forkert brugernummer eller kodeord"

  Scenario: I login with incorrect username but correct password
    When I login as "66x45" with password "Nota1234"
    Then I see an error message "Forkert brugernummer eller kodeord"

  Scenario: When I login then close and opens the tab, I'm still logged in
    Given I login as "66846" with password "Nota1234"
    And I close the tab
    And I open a tab 
    When I visit "/"
    Then I see a list of books

