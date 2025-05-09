SELECT
  A."consecutive_number",
  A."county",
  A."type_of_intersection",
  A."light_condition",
  A."atmospheric_conditions_1",
  A."hour_of_crash",
  A."functional_system",
  A."related_factors_crash_level_1" AS "related_factors",
  CASE
    WHEN A."hour_of_ems_arrival_at_hospital" BETWEEN 0 AND 23 AND A."minute_of_ems_arrival_at_hospital" BETWEEN 0 AND 59 THEN
      ROUND(
        (A."hour_of_ems_arrival_at_hospital" + A."minute_of_ems_arrival_at_hospital" / 60.0)
        - (A."hour_of_crash" + A."minute_of_crash" / 60.0),
        4
      )
    ELSE NULL
  END AS "delay_to_hospital",
  CASE
    WHEN A."hour_of_arrival_at_scene" BETWEEN 0 AND 23 AND A."minute_of_arrival_at_scene" BETWEEN 0 AND 59 THEN
      ROUND(
        (A."hour_of_arrival_at_scene" + A."minute_of_arrival_at_scene" / 60.0)
        - (A."hour_of_crash" + A."minute_of_crash" / 60.0),
        4
      )
    ELSE NULL
  END AS "delay_to_scene",
  P."age",
  P."person_type",
  P."seating_position",
  ROUND(
    CASE
      WHEN P."restraint_system_helmet_use" = 0 THEN 0.0
      WHEN P."restraint_system_helmet_use" = 1 THEN 0.33
      WHEN P."restraint_system_helmet_use" = 2 THEN 0.67
      WHEN P."restraint_system_helmet_use" = 3 THEN 1.0
      ELSE 0.5
    END,
    4
  ) AS "restraint",
  CASE
    WHEN P."injury_severity" = 4 THEN 1
    ELSE 0
  END AS "survived",
  CASE
    WHEN V."rollover" = 'No Rollover' THEN 0
    ELSE 1
  END AS "rollover",
  CASE
    WHEN P."air_bag_deployed" BETWEEN 1 AND 9 THEN 1
    ELSE 0
  END AS "airbag",
  CASE
    WHEN P."police_reported_alcohol_involvement" LIKE '%Yes%' THEN 1
    ELSE 0
  END AS "alcohol",
  CASE
    WHEN P."police_reported_drug_involvement" LIKE '%Yes%' THEN 1
    ELSE 0
  END AS "drugs",
  P."related_factors_person_level1",
  V."travel_speed",
  CASE
    WHEN V."speeding_related" LIKE '%Yes%' THEN 1
    ELSE 0
  END AS "speeding_related",
  V."extent_of_damage",
  V."body_type",
  V."vehicle_removal",
  CASE
    WHEN A."manner_of_collision" <= 11 THEN A."manner_of_collision"
    ELSE 11
  END AS "manner_of_collision",
  CASE
    WHEN V."roadway_surface_condition" <= 8 THEN V."roadway_surface_condition"
    ELSE 8
  END AS "roadway_surface_condition",
  CASE
    WHEN A."first_harmful_event" < 90 THEN A."first_harmful_event"
    ELSE 0
  END AS "first_harmful_event",
  CASE
    WHEN V."most_harmful_event" < 90 THEN V."most_harmful_event"
    ELSE 0
  END AS "most_harmful_event"
FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2015 A
JOIN NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.VEHICLE_2015 V
  ON A."consecutive_number" = V."consecutive_number"
JOIN NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.PERSON_2015 P
  ON A."consecutive_number" = P."consecutive_number" AND V."vehicle_number" = P."vehicle_number";