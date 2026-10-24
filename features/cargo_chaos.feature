Feature: Cargo chaos
  Treasure chests strain in their ropes, break loose and burst (Olivier, 2026-10-24)

  Scenario: A hard hit
    When the ship crashes or a cannonball lands
    Then lashed chests may snap their ropes and slide across the deck with momentum
    And a loose chest may burst open, spilling half its gold on the deck

  Scenario: Losing the gold
    Given spilled gold near the rails
    When another big lurch comes or the deck floods
    Then some gold washes overboard and the cargo is worth less
    But gold carried back to a chest goes back in
