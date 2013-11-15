Feature: An E17 member can navigate through bookshelf and more.
  As an E17 member I can navigate the bookshelf and select a book.

  Background: I log in using member login
    Given I visit '/'
    And I login as E17 test user

  Scenario: See bookshelf
    Then I see a list of books

  Scenario: Find book
    When I search for "Harry potter"
    Then I see a link "Harry Potter og fangen fra Azkaban" to "#book-details?book=13984"

