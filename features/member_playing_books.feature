Feature: An E17 member playing books

  Background: I log in using member login
    Given I visit "/"
    And I login as E17 test user
    And I wait for hourglass to appear and disappear

  Scenario: I play through an entire section
    # Den mystiske sag om hunden i natten af Haddon, Mark
    Given I play book "33852"
    And I play the book for the first time
    And I click "Afspil"
    And I wait for the next section to start
    Then the book is playing
