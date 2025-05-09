SELECT
  a.consecutive_number,                                         -- 1
  a.county,                                                     -- 2
  a.type_of_intersection,                                       -- 3
  a.light_condition,                                            -- 4
  a.atmospheric_conditions_1,                                   -- 5
  a.hour_of_crash,                                              -- 6
  a.functional_system,                                          -- 7
  a.related_factors_crash_level_1           AS related_factors, -- 8

  /* 9  : delay_to_hospital  */
  CASE
    WHEN a.hour_of_ems_arrival_at_hospital BETWEEN 0 AND 23
         AND a.hour_of_crash BETWEEN 0 AND 23
    THEN a.hour_of_ems_arrival_at_hospital - a.hour_of_crash
    ELSE NULL
  END                                            AS delay_to_hospital,

  /* 10 : delay_to_scene    */
  CASE
    WHEN a.hour_of_arrival_at_scene BETWEEN 0 AND 23
         AND a.hour_of_crash BETWEEN 0 AND 23
    THEN a.hour_of_arrival_at_scene - a.hour_of_crash
    ELSE NULL
  END                                            AS delay_to_scene,

  p.age,                                                        -- 11
  p.person_type,                                                -- 12
  p.seating_position,                                           -- 13

  /* 14 : restraint level   */
  CASE p.restraint_system_helmet_use
       WHEN 0 THEN 0
       WHEN 1 THEN 0.33
       WHEN 2 THEN 0.67
       WHEN 3 THEN 1.0
       ELSE 0.5
  END                                            AS restraint,

  /* 15 : survived flag     */
  CASE WHEN p.injury_severity = 4 THEN 1 ELSE 0 END AS survived,

  /* 16 : rollover binary   */
  CASE WHEN v.rollover LIKE 'No Rollover%' THEN 0 ELSE 1 END     AS rollover,

  /* 17 : air‑bag binary    */
  CASE WHEN p.air_bag_deployed BETWEEN 1 AND 9 THEN 1 ELSE 0 END AS airbag,

  /* 18 : alcohol binary    */
  CASE
    WHEN LOWER(p.police_reported_alcohol_involvement) LIKE '%yes%' THEN 1
    ELSE 0
  END                                            AS alcohol,

  /* 19 : drugs binary      */
  CASE
    WHEN LOWER(p.police_reported_drug_involvement) LIKE '%yes%' THEN 1
    ELSE 0
  END                                            AS drugs,

  p.related_factors_person_level1,                               -- 20
  v.travel_speed,                                                -- 21

  /* 22 : speeding_related  */
  CASE
    WHEN LOWER(v.speeding_related) LIKE '%yes%' THEN 1 ELSE 0
  END                                            AS speeding_related,

  v.extent_of_damage,                                           -- 23
  v.body_type,                                                  -- 24
  v.vehicle_removal,                                            -- 25

  /* 26 : capped manner_of_collision (accident level) */
  CASE
    WHEN a.manner_of_collision > 11 THEN 11
    ELSE a.manner_of_collision
  END                                            AS manner_of_collision,

  /* 27 : capped roadway_surface_condition (vehicle level) */
  CASE
    WHEN v.roadway_surface_condition > 8 THEN 8
    ELSE v.roadway_surface_condition
  END                                            AS roadway_surface_condition,

  /* 28 : first_harmful_event (<90 else 0) */
  CASE
    WHEN a.first_harmful_event < 90 THEN a.first_harmful_event
    ELSE 0
  END                                            AS first_harmful_event,

  /* 29 : most_harmful_event (<90 else 0)  */
  CASE
    WHEN v.most_harmful_event < 90 THEN v.most_harmful_event
    ELSE 0
  END                                            AS most_harmful_event

FROM   `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015` AS a
JOIN   `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2015`  AS v
       ON  a.consecutive_number = v.consecutive_number
JOIN   `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`   AS p
       ON  a.consecutive_number = p.consecutive_number
       AND v.vehicle_number      = p.vehicle_number

WHERE  a.year_of_crash = 2015;