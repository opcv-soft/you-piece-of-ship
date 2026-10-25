Feature: Fishing
  So that idle crew always have something fun to do (Olivier, 2026-10-22)

  Scenario: Catching a fish
    Given a crew member at a fishing spot with the line cast
    When the float dips and they press Jump in time
    Then they catch something (sardine, goldfish, squid, pufferfish or, rarely, treasure)
    And its points are added to the voyage score

  Scenario: AI fish only when all is calm
    Given an AI carpenter with nothing to repair
    Then it goes fishing
    When a leak opens
    Then it reels in and goes to fix it

  Scenario: Fish are easy to catch
    Given a crew member at a fishing spot with the line cast
    Then three tugs in four are real bites (the rest are nibbles)
    And after a bite they have 1.35 to 2.4 seconds to press Jump
