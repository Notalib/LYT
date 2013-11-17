Feature: An anonymous user navigates LYT.
  As an anonymous user I navigate around LYT.

  Background: I am an anonymous user.
    Given I visit '/'

  Scenario: I read the support page.
    When I click "Support"
    Then I see a link "nulstille dit kodeord på E17.dk" to "https://www.e17.dk/unifiedlogin/password"
    Then I see a link "kontakte E17 Support på mail" to "mailto:e17support@nota.nu"
    Then I see a link "Ring: 39 13 46 00" to "tel:+4539134600"

  Scenario: I read the support page.
    When I click "Prøv E17 Direkte uden login"
    And I wait for the hourglass
    And I search for "Harry potter"
    And I see a link "Harry Potter og fangen fra Azkaban" to "#book-details?book=13984"
    When I click "Harry Potter og fangen fra Azkaban"
    Then I see "Harry Potter og fangen fra Azkaban (3)"
    And I see "Indlæst af: Thomas Gulstad"

