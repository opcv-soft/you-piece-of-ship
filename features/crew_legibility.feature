Feature: You can tell who's who and what each crewmate is doing
  Olivier, 2026-10-24: "It's hard to read, hard to understand what the other AI are doing."

  Scenario: Colour rings and big tags
    Then every crew member has a ring in their colour under their feet and a big P-tag

  Scenario: Job icons follow what an AI is actually doing
    Given an AI hired as carpenter is sent to steer
    Then the icon over its head is the helm wheel, not a hammer

  Scenario: The crew panel
    Then a corner panel lists P1 to P4 with their colour, job icon and one word like "Steering"

  Scenario: Quieter crew
    When an AI changes plan
    Then only the crew panel says so, unless it's urgent ("Too hot! Venting!")

  Scenario: You never lose yourself
    When a human works a station
    Then their character stays solid (only AI crewmates fade)

  Scenario: One card per thing
    When two players stand by the pump
    Then only the nearest one sees its card
