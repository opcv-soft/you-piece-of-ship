
  Scenario: Debris floats, then swooshes aboard into its pile
    Given the crew smashes a barrel
    Then its pieces bob on the water for a moment
    And then fly in arcs onto the ship into the gold bucket

  Scenario: Every hit pays, not only the final break
    Given a charcoal rock
    When a cannonball hits it once, or the ship bumps it gently
    Then a lump of charcoal flies aboard even though the rock still stands
