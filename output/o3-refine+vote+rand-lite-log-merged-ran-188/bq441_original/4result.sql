SELECT
  -- accident–level fields
  acc.consecutive_number,
  acc.county,
  acc.type_of_intersection,
  acc.light_condition,
  acc.atmospheric_conditions_1,
  acc.hour_of_crash,
  acc.functional_system,
  acc.related_factors_crash_level_1            AS related_factors,

  -- time–delay metrics
  CASE
    WHEN acc.hour_of_ems_arrival_at_hospital BETWEEN 0 AND 23
    THEN acc.hour_of_ems_arrival_at_hospital - acc.hour_of_crash
  END                                           AS delay_to_hospital,
  CASE
    WHEN acc.hour_of_arrival_at_scene BETWEEN 0 AND 23
    THEN acc.hour_of_arrival_at_scene - acc.hour_of_crash
  END                                           AS delay_to_scene,

  -- person–level fields
  p.age,
  p.person_type,
  p.seating_position,
  CASE p.restraint_system_helmet_use
       WHEN 0 THEN 0
       WHEN 1 THEN 0.33
       WHEN 2 THEN 0.67
       WHEN 3 THEN 1.0
       ELSE 0.5
  END                                           AS restraint,
  CASE WHEN p.injury_severity = 4 THEN 1 ELSE 0 END AS survived,
  CASE WHEN p.air_bag_deployed BETWEEN 1 AND 9  THEN 1 ELSE 0 END AS airbag,
  CASE WHEN LOWER(p.police_reported_alcohol_involvement) LIKE '%yes%' THEN 1 ELSE 0 END AS alcohol,
  CASE WHEN LOWER(p.police_reported_drug_involvement)   LIKE '%yes%' THEN 1 ELSE 0 END AS drugs,
  p.related_factors_person_level1,

  -- vehicle–level fields
  CASE WHEN LOWER(veh.rollover) NOT LIKE '%no rollover%' THEN 1 ELSE 0 END AS rollover,
  veh.travel_speed,
  CASE WHEN LOWER(veh.speeding_related) LIKE '%yes%' THEN 1 ELSE 0 END AS speeding_related,
  veh.extent_of_damage,
  veh.body_type,
  veh.vehicle_removal,
  CASE WHEN acc.manner_of_collision > 11 THEN 11 ELSE acc.manner_of_collision END AS manner_of_collision,
  CASE WHEN veh.roadway_surface_condition > 8 THEN 8 ELSE veh.roadway_surface_condition END AS roadway_surface_condition,
  CASE WHEN acc.first_harmful_event  < 90 THEN acc.first_harmful_event  ELSE 0 END AS first_harmful_event,
  CASE WHEN veh.most_harmful_event   < 90 THEN veh.most_harmful_event   ELSE 0 END AS most_harmful_event
FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`   AS p
LEFT JOIN `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015` AS acc
  ON p.consecutive_number = acc.consecutive_number
LEFT JOIN `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2015`  AS veh
  ON p.consecutive_number = veh.consecutive_number
 AND p.vehicle_number      = veh.vehicle_number;