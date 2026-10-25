
  Scenario: Debris floats, then swooshes aboard into its pile
    Given the crew smashes a barrel
    Then its pieces bob on the water for a moment
    And then fly in arcs onto the ship into the gold bucket

  Scenario: Even a gentle bump pays
    Given a charcoal rock
    When the ship bumps it gently
    Then a lump of charcoal flies aboard even though the rock still stands

  Scenario: Sirens on a skewer
    Given the crew shoots a siren once
    Then she flies aboard and is skewered on the bowsprit, curled up like a shrimp
    And each new siren goes a little further in along the pole

  Scenario: One shot breaks anything
    Given a rock, wreck, whale, siren or barrel
    When one cannonball hits it
    Then it breaks and all its loot flies aboard
