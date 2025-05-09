/*  Critical details for 2015 traffic-fatality crashes  */

SELECT
  /* ---------- crash-level (ACCIDENT) ------------------------------- */
  a.`consecutive_number`                                             AS consecutive_number,
  a.`county`,
  a.`type_of_intersection`,
  a.`light_condition`,
  a.`atmospheric_conditions_1`,
  a.`hour_of_crash`,
  a.`functional_system`,
  a.`related_factors_crash_level_1`                                  AS related_factors,

  /* delay (hrs) from crash to EMS arrival on scene / at hospital */
  CASE
      WHEN a.`hour_of_arrival_at_scene` BETWEEN 0 AND 23
      THEN a.`hour_of_arrival_at_scene` - a.`hour_of_crash`
  END                                                                AS delay_to_scene,
  CASE
      WHEN a.`hour_of_ems_arrival_at_hospital` BETWEEN 0 AND 23
      THEN a.`hour_of_ems_arrival_at_hospital` - a.`hour_of_crash`
  END                                                                AS delay_to_hospital,

  /* ---------- person-level (PERSON) -------------------------------- */
  p.`age`,
  p.`person_type`,
  p.`seating_position`,

  /* restraint score */
  CASE p.`restraint_system_helmet_use`
      WHEN 0 THEN 0
      WHEN 1 THEN 0.33
      WHEN 2 THEN 0.67
      WHEN 3 THEN 1.00
      ELSE 0.50
  END                                                                AS restraint,

  /* survived flag (injury severity 4) */
  CASE WHEN p.`injury_severity` = 4 THEN 1 ELSE 0 END               AS survived,

  /* alcohol / drug involvement */
  CASE
      WHEN LOWER(p.`police_reported_alcohol_involvement`) LIKE '%yes%' THEN 1 ELSE 0
  END                                                                AS alcohol,
  CASE
      WHEN LOWER(p.`police_reported_drug_involvement`)   LIKE '%yes%' THEN 1 ELSE 0
  END                                                                AS drugs,

  p.`related_factors_person_level1`,

  /* air-bag deployment binary (1-9 = deployed) */
  CASE WHEN p.`air_bag_deployed` BETWEEN 1 AND 9 THEN 1 ELSE 0 END   AS airbag,

  /* ---------- vehicle-level (VEHICLE) ------------------------------ */
  CASE WHEN v.`rollover` LIKE 'No Rollover' THEN 0 ELSE 1 END        AS rollover,

  v.`travel_speed`,

  /* speeding-related binary */
  CASE
      WHEN LOWER(v.`speeding_related`) LIKE '%yes%' THEN 1 ELSE 0
  END                                                                AS speeding_related,

  v.`extent_of_damage`,
  v.`body_type`,
  v.`vehicle_removal`,

  /* capped values */
  CASE WHEN v.`manner_of_collision`       > 11 THEN 11 ELSE v.`manner_of_collision`      END AS manner_of_collision,
  CASE WHEN v.`roadway_surface_condition` >  8 THEN  8 ELSE v.`roadway_surface_condition`END AS roadway_surface_condition,

  /* harmful events (<90 kept, else 0) */
  CASE WHEN v.`first_harmful_event` < 90 THEN v.`first_harmful_event` ELSE 0 END         AS first_harmful_event,
  CASE WHEN v.`most_harmful_event`  < 90 THEN v.`most_harmful_event`  ELSE 0 END         AS most_harmful_event

FROM  `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015` AS a
LEFT  JOIN `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`   AS p
       ON a.`consecutive_number` = p.`consecutive_number`
LEFT  JOIN `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2015`  AS v
       ON a.`consecutive_number` = v.`consecutive_number`

LIMIT 100;