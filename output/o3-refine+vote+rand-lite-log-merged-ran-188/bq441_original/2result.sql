SELECT
  consecutive_number,
  county,
  type_of_intersection,
  light_condition,
  atmospheric_conditions_1,
  hour_of_crash,
  functional_system,
  related_factors_crash_level_1 AS related_factors,
  -- delay_to_hospital: EMS hospital arrival hour minus crash hour
  CASE
    WHEN hour_of_ems_arrival_at_hospital BETWEEN 0 AND 23
         AND hour_of_crash BETWEEN 0 AND 23
    THEN hour_of_ems_arrival_at_hospital - hour_of_crash
    ELSE NULL
  END AS delay_to_hospital,
  -- delay_to_scene: arrival‑at‑scene hour minus crash hour
  CASE
    WHEN hour_of_arrival_at_scene BETWEEN 0 AND 23
         AND hour_of_crash BETWEEN 0 AND 23
    THEN hour_of_arrival_at_scene - hour_of_crash
    ELSE NULL
  END AS delay_to_scene
FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015`;