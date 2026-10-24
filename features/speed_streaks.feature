Feature: Speed streaks on the water
  So that acceleration is visible without looking at the HUD (Olivier, 2026-10-24)

  Scenario: Still ship
    Given the ship is not moving
    Then no streaks slide under it

  Scenario: Speeding up
    When the ship gains speed
    Then translucent streaks fade in, stretch and flow past opposite to its real velocity
    And they turn with the ship and reverse when it goes astern
