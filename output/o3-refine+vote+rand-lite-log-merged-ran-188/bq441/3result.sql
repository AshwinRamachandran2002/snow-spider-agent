/*  Critical crash, vehicle and person details – Fatality Analysis Reporting System 2015  */

WITH vehicle_summary AS (   -- one representative vehicle row per crash
  SELECT
    consecutive_number,
    ANY_VALUE(rollover)                  AS rollover_txt,
    ANY_VALUE(travel_speed)              AS travel_speed,
    ANY_VALUE(speeding_related)          AS speeding_related_txt,
    ANY_VALUE(extent_of_damage)          AS extent_of_damage,
    ANY_VALUE(body_type)                 AS body_type,
    ANY_VALUE(vehicle_removal)           AS vehicle_removal,
    ANY_VALUE(roadway_surface_condition) AS roadway_surface_condition,
    ANY_VALUE(most_harmful_event)        AS most_harmful_event
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2015`
  GROUP BY consecutive_number
)

SELECT
  /* ---------------- crash level ---------------- */
  a.consecutive_number,
  a.county,
  a.hour_of_crash,
  a.functional_system,
  a.type_of_intersection,
  a.light_condition,
  a.atmospheric_conditions_1,
  a.related_factors_crash_level_1                         AS related_factors,
  /* delays */
  CASE
    WHEN a.hour_of_ems_arrival_at_hospital BETWEEN 0 AND 23
         AND a.hour_of_crash BETWEEN 0 AND 23
    THEN a.hour_of_ems_arrival_at_hospital - a.hour_of_crash
  END                                                     AS delay_to_hospital,
  CASE
    WHEN a.hour_of_arrival_at_scene BETWEEN 0 AND 23
         AND a.hour_of_crash BETWEEN 0 AND 23
    THEN a.hour_of_arrival_at_scene - a.hour_of_crash
  END                                                     AS delay_to_scene,
  /* capped crash fields */
  CASE WHEN a.manner_of_collision > 11
       THEN 11 ELSE a.manner_of_collision END             AS manner_of_collision,
  CASE WHEN a.first_harmful_event < 90
       THEN a.first_harmful_event ELSE 0 END             AS first_harmful_event,

  /* ---------------- person level ---------------- */
  p.age,
  p.person_type,
  p.seating_position,
  CASE p.restraint_system_helmet_use
       WHEN 0 THEN 0.00
       WHEN 1 THEN 0.33
       WHEN 2 THEN 0.67
       WHEN 3 THEN 1.00
       ELSE 0.50 END                                      AS restraint,
  CASE WHEN p.injury_severity = 4 THEN 1 ELSE 0 END       AS survived,
  CASE WHEN p.police_reported_alcohol_involvement LIKE 'Yes%' THEN 1 ELSE 0 END AS alcohol,
  CASE WHEN p.police_reported_drug_involvement   LIKE 'Yes%' THEN 1 ELSE 0 END AS drugs,
  p.related_factors_person_level1,
  /* airbag (person-level) */
  CASE WHEN p.air_bag_deployed BETWEEN 1 AND 9 THEN 1 ELSE 0 END AS airbag,

  /* ---------------- vehicle level ---------------- */
  v.travel_speed,
  CASE WHEN v.speeding_related_txt LIKE 'Yes%' THEN 1 ELSE 0 END AS speeding_related,
  v.extent_of_damage,
  v.body_type,
  v.vehicle_removal,
  CASE WHEN v.rollover_txt = 'No Rollover' THEN 0 ELSE 1 END      AS rollover,
  CASE WHEN v.roadway_surface_condition > 8
       THEN 8 ELSE v.roadway_surface_condition END                AS roadway_surface_condition,
  CASE WHEN v.most_harmful_event < 90
       THEN v.most_harmful_event ELSE 0 END                       AS most_harmful_event

FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015` AS a
JOIN `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`   AS p
  ON a.consecutive_number = p.consecutive_number
LEFT JOIN vehicle_summary AS v
  ON a.consecutive_number = v.consecutive_number;