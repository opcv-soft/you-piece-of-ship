Feature: Sea battles
  So that pirates make some routes exciting (Olivier, 2026-10-22)

  Scenario: Pirates attack from the side
    Given pirates appear on the port side
    When they come level with the ship
    Then they fire a broadside, and a ball that lands on deck cracks the hull

  Scenario: Fight back
    Given a cannonball from the rack in the middle of the deck
    When a crew member loads a port cannon, aims with the stick and presses Jump
    Then the ball flies out and three hits sink the pirates
    And floating loot appears that the ship scoops up by sailing through it

  Scenario: Outrun them
    When the ship sails at full throttle
    Then the pirates fall behind and give up

  Scenario: The aim guide shows where the ball will land
    Given a player takes a cannon
    Then a dotted line runs across the water to a ring where the ball will land
    And it turns gold when the shot would hit a pirate ship or anything breakable

  Scenario: Broadsides you see coming
    Given pirates are level with the ship and their guns are loaded
    When they take aim
    Then their gun ports open on our side and red rings mark where each ball will land, 2 seconds ahead
    And the balls land exactly in those rings

  Scenario: Dodge the rings
    Given red rings are on the deck
    When the helmsman speeds up, slows down or turns so the deck leaves the rings
    Then the balls splash into the sea and the hull is not hit

  Scenario: Shoot first
    Given pirates are taking aim
    When one of our cannonballs hits them before they fire
    Then their broadside is spoiled: the rings vanish and they have to reload
