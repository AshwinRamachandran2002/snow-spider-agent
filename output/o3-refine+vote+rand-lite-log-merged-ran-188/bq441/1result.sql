-- Description:  Consolidate crash, person, and vehicle details
-- (per “Traffic Fatalities Info List 2015”) for all 2015 fatal crashes.

SELECT DISTINCT
  /* ---------------- Crash-level fields ---------------- */
  a.consecutive_number,                         -- 1
  a.county,                                     -- 2
  a.type_of_intersection,                       -- 3
  a.light_condition,                            -- 4
  a.atmospheric_conditions_1,                   -- 5
  a.hour_of_crash,                              -- 6
  a.functional_system,                          -- 7
  a.related_factors_crash_level_1 AS related_factors,        -- 8

  /* Delay calculations (items 9 & 10) */
  CASE
    WHEN a.hour_of_arrival_at_scene BETWEEN 0 AND 23
    THEN a.hour_of_arrival_at_scene - a.hour_of_crash
  END                                                    AS delay_to_scene,      -- 10
  CASE
    WHEN a.hour_of_ems_arrival_at_hospital BETWEEN 0 AND 23
    THEN a.hour_of_ems_arrival_at_hospital - a.hour_of_crash
  END                                                    AS delay_to_hospital,   -- 9

  /* ---------------- Person-level fields ---------------- */
  p.age,                                      -- 11
  p.person_type,                              -- 12
  p.seating_position,                         -- 13

  /* Restraint score (item 14) */
  CASE p.restraint_system_helmet_use
      WHEN 0 THEN 0
      WHEN 1 THEN 0.33
      WHEN 2 THEN 0.67
      WHEN 3 THEN 1.00
      ELSE 0.50
  END                                         AS restraint,                    -- 14

  /* Survival & substance flags (items 15, 18, 19) */
  CASE WHEN p.injury_severity = 4 THEN 1 ELSE 0 END          AS survived,      -- 15
  CASE WHEN LOWER(p.police_reported_alcohol_involvement) LIKE '%yes%' THEN 1 ELSE 0 END
                                                AS alcohol,                    -- 18
  CASE WHEN LOWER(p.police_reported_drug_involvement)   LIKE '%yes%' THEN 1 ELSE 0 END
                                                AS drugs,                      -- 19
  p.related_factors_person_level1,                                     -- 20

  /* ---------------- Vehicle-level fields ---------------- */
  v.travel_speed,                              -- 21
  /* Speeding indicator (item 22) */
  CASE WHEN LOWER(v.speeding_related) LIKE 'yes%' THEN 1 ELSE 0 END
                                                AS speeding_related,           -- 22
  v.extent_of_damage,                          -- 23
  v.body_type,                                 -- 24
  v.vehicle_removal,                           -- 25

  /* Binary rollover & airbag flags (items 16 & 17) */
  CASE WHEN v.rollover LIKE 'No%' THEN 0 ELSE 1 END         AS rollover,       -- 16
  CASE WHEN p.air_bag_deployed BETWEEN 1 AND 9 THEN 1 ELSE 0 END
                                                AS airbag,                     -- 17

  /* Manner of collision & roadway surface with capping (items 26 & 27) */
  CASE WHEN v.manner_of_collision > 11 THEN 11 ELSE v.manner_of_collision END
                                                AS manner_of_collision,        -- 26
  CASE WHEN v.roadway_surface_condition > 8  THEN 8  ELSE v.roadway_surface_condition END
                                                AS roadway_surface_condition,  -- 27

  /* First/Most harmful event after <90 check (items 28 & 29) */
  CASE WHEN v.first_harmful_event < 90 THEN v.first_harmful_event ELSE 0 END
                                                AS first_harmful_event,        -- 28
  CASE WHEN v.most_harmful_event  < 90 THEN v.most_harmful_event  ELSE 0 END
                                                AS most_harmful_event          -- 29
FROM  `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015` AS a
LEFT  JOIN `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`   AS p
       ON a.consecutive_number = p.consecutive_number
LEFT  JOIN `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2015`  AS v
       ON a.consecutive_number = v.consecutive_number;