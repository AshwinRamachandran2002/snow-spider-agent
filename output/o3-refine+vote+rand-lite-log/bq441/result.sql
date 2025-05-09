SELECT
  /* ----------  Accident‑level fields  ---------- */
  a.consecutive_number,
  a.county,
  a.type_of_intersection,
  a.light_condition,
  a.atmospheric_conditions_1,
  a.hour_of_crash,
  a.functional_system,
  a.related_factors_crash_level_1        AS related_factors,
  CASE
      WHEN a.hour_of_ems_arrival_at_hospital BETWEEN 0 AND 23
           THEN a.hour_of_ems_arrival_at_hospital - a.hour_of_crash
      ELSE NULL
  END                                      AS delay_to_hospital,
  CASE
      WHEN a.hour_of_arrival_at_scene BETWEEN 0 AND 23
           THEN a.hour_of_arrival_at_scene - a.hour_of_crash
      ELSE NULL
  END                                      AS delay_to_scene,

  /* ----------  Person‑level fields  ---------- */
  p.age,
  p.person_type,
  p.seating_position,
  CASE p.restraint_system_helmet_use
      WHEN 0 THEN 0
      WHEN 1 THEN 0.33
      WHEN 2 THEN 0.67
      WHEN 3 THEN 1.0
      ELSE 0.5
  END                                      AS restraint,
  CASE WHEN p.injury_severity = 4                               THEN 1 ELSE 0 END  AS survived,
  CASE WHEN LOWER(p.rollover) LIKE '%rollover%'                  THEN 1 ELSE 0 END  AS rollover,
  CASE WHEN p.air_bag_deployed BETWEEN 1 AND 9                  THEN 1 ELSE 0 END  AS airbag,
  CASE WHEN LOWER(p.police_reported_alcohol_involvement) LIKE '%yes%' THEN 1 ELSE 0 END  AS alcohol,
  CASE WHEN LOWER(p.police_reported_drug_involvement)   LIKE '%yes%' THEN 1 ELSE 0 END  AS drugs,
  p.related_factors_person_level1,

  /* ----------  Vehicle‑level fields  ---------- */
  v.travel_speed,
  CASE WHEN LOWER(v.speeding_related) LIKE '%yes%'               THEN 1 ELSE 0 END  AS speeding_related,
  v.extent_of_damage,
  v.body_type,
  v.vehicle_removal,
  CASE WHEN v.manner_of_collision > 11                          THEN 11 ELSE v.manner_of_collision END AS manner_of_collision,
  CASE WHEN v.roadway_surface_condition > 11                    THEN 8  ELSE v.roadway_surface_condition END AS roadway_surface_condition,
  CASE WHEN v.first_harmful_event  < 90                         THEN v.first_harmful_event  ELSE 0 END AS first_harmful_event,
  CASE WHEN v.most_harmful_event  < 90                          THEN v.most_harmful_event  ELSE 0 END AS most_harmful_event
FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015` AS a
JOIN `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`   AS p
  ON a.state_number       = p.state_number
 AND a.consecutive_number = p.consecutive_number
JOIN `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2015`  AS v
  ON p.state_number       = v.state_number
 AND p.consecutive_number = v.consecutive_number
 AND p.vehicle_number     = v.vehicle_number;