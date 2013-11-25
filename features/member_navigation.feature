Feature: An E17 member can navigate through bookshelf and more.
  As an E17 member I can navigate the bookshelf and select a book.

  Background: I log in using member login
    Given I visit "/"
    And I login as E17 test user
    And I wait for hourglass to appear and disappear

  Scenario: See bookshelf
    Then I see a list of books

  Scenario: Find book
    When I search for "Harry potter"
    Then I see a link "Harry Potter og fangen fra Azkaban" to "#book-details?book=13984"
    Then I click "Harry Potter og fangen fra Azkaban"
    Then I see "Harry Potter og fangen fra Azkaban (3)"
    And I see "Indlæst af: Thomas Gulstad"
    When I click "Tilføj til mine bøger"
    Then I see "Mine bøger"
    Then I see a link "Harry Potter og fangen fra Azkaban" to "#book-player?book=13984"
