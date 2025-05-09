SELECT
  ACC."consecutive_number",
  ACC."county",
  ACC."type_of_intersection",
  ACC."light_condition",
  ACC."atmospheric_conditions_1",
  ACC."hour_of_crash",
  ACC."functional_system",
  ACC."related_factors_crash_level_1" AS "related_factors",
  CASE
    WHEN ACC."hour_of_ems_arrival_at_hospital" BETWEEN 0 AND 23 THEN ROUND(ACC."hour_of_ems_arrival_at_hospital" - ACC."hour_of_crash", 4)
    ELSE NULL
  END AS "delay_to_hospital",
  CASE
    WHEN ACC."hour_of_arrival_at_scene" BETWEEN 0 AND 23 THEN ROUND(ACC."hour_of_arrival_at_scene" - ACC."hour_of_crash", 4)
    ELSE NULL
  END AS "delay_to_scene",
  PER."age",
  PER."person_type",
  PER."seating_position",
  CASE PER."restraint_system_helmet_use"
    WHEN 0 THEN 0.0000
    WHEN 1 THEN 0.3300
    WHEN 2 THEN 0.6700
    WHEN 3 THEN 1.0000
    ELSE 0.5000
  END AS "restraint",
  CASE WHEN PER."injury_severity" = 4 THEN 1 ELSE 0 END AS "survived",
  CASE WHEN UPPER(VEH."rollover") LIKE '%ROLLOVER%' THEN 1 ELSE 0 END AS "rollover",
  CASE WHEN PER."air_bag_deployed" BETWEEN 1 AND 9 THEN 1 ELSE 0 END AS "airbag",
  CASE WHEN UPPER(PER."police_reported_alcohol_involvement") LIKE '%YES%' THEN 1 ELSE 0 END AS "alcohol",
  CASE WHEN UPPER(PER."police_reported_drug_involvement") LIKE '%YES%' THEN 1 ELSE 0 END AS "drugs",
  PER."related_factors_person_level1",
  VEH."travel_speed",
  CASE WHEN UPPER(VEH."speeding_related") LIKE '%YES%' THEN 1 ELSE 0 END AS "speeding_related",
  VEH."extent_of_damage",
  VEH."body_type",
  VEH."vehicle_removal",
  CASE WHEN ACC."manner_of_collision" > 11 THEN 11 ELSE ACC."manner_of_collision" END AS "manner_of_collision",
  CASE WHEN VEH."roadway_surface_condition" > 8 THEN 8 ELSE VEH."roadway_surface_condition" END AS "roadway_surface_condition",
  CASE WHEN ACC."first_harmful_event" < 90 THEN ACC."first_harmful_event" ELSE 0 END AS "first_harmful_event",
  CASE WHEN VEH."most_harmful_event" < 90 THEN VEH."most_harmful_event" ELSE 0 END AS "most_harmful_event"
FROM
  NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES."ACCIDENT_2015" ACC
  JOIN NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES."VEHICLE_2015" VEH
    ON ACC."state_number" = VEH."state_number" AND ACC."consecutive_number" = VEH."consecutive_number"
  JOIN NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES."PERSON_2015" PER
    ON ACC."state_number" = PER."state_number" AND ACC."consecutive_number" = PER."consecutive_number" AND VEH."vehicle_number" = PER."vehicle_number";