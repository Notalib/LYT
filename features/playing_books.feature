@supported_browser
Feature: An anonymous user playing books.
  As an anonymous user I play a book

  Background: I am an anonymous user
    Given I visit "/"
    And I wait for the login screen
    And I click "Prøv E17 Direkte uden login"
    And I wait for hourglass to appear and disappear

  Scenario: I am playing a book from first section
    When I click "Gangsta rap Benjamin Zephaniah"
    And I wait for hourglass to appear and disappear
#    Then I see "Gangsta Rap af Benjamin Zephaniah"
    And I click "Indholdsfortegnelse"
    And I click "Benjamin Zephaniah: Gangsta Rap"
    And I click "Afspil"
    Then the book is playing file at 0:00

  Scenario: I am playing a book from sub section
    When I click "Gangsta rap Benjamin Zephaniah"
    And I wait for hourglass to appear and disappear
    And I click "Indholdsfortegnelse"
    And I click "underafsnit til Benjamin Zephaniah: Gangsta Rap"
    And I click "Om denne udgave"
    And I click "Afspil"
    Then the book is playing file at 0:00

  Scenario: I am skipping backward across sections/sound file
    When I click "Gangsta rap Benjamin Zephaniah"
    And I wait for hourglass to appear and disappear
    And I click "Indholdsfortegnelse"
    And I click "underafsnit til Benjamin Zephaniah: Gangsta Rap"
    And I click "Kolofon og bibliografiske oplysninger"
    And I click "Afspil"
    Then the book is playing file at 0:00
    And I click "Tilbage 15 sekunder"
    Then the book is playing file at 0:17
    
  Scenario: I am skipping backward less than 15 seconds into the book
    When I click "Gangsta rap Benjamin Zephaniah"
    And I wait for hourglass to appear and disappear
    And I click "Indholdsfortegnelse"
    And I click "underafsnit til Benjamin Zephaniah: Gangsta Rap"
    And I click "Om denne udgave"
    And I click "Afspil"
    Then the book is playing file at 0:00
    And I click "Tilbage 15 sekunder"
    Then the book is playing file at 0:00
    


