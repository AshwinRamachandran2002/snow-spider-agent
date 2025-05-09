-- Critical 2015 crash, vehicle and person details with all requested derived fields
SELECT
  /*  1 */ a.consecutive_number,
  /*  2 */ a.state_number,
  /*  3 */ a.county,
  /*  4 */ a.type_of_intersection,
  /*  5 */ a.light_condition,
  /*  6 */ a.atmospheric_conditions_1,
  /*  7 */ a.hour_of_crash,
  /*  8 */ a.functional_system,
  /*  9 */ a.related_factors_crash_level_1        AS related_factors,

  /* 10 */ CASE
             WHEN a.hour_of_arrival_at_scene BETWEEN 0 AND 23
                  AND a.hour_of_crash            BETWEEN 0 AND 23
             THEN a.hour_of_arrival_at_scene - a.hour_of_crash
           END                                    AS delay_to_scene,

  /* 11 */ CASE
             WHEN a.hour_of_ems_arrival_at_hospital BETWEEN 0 AND 23
                  AND a.hour_of_crash               BETWEEN 0 AND 23
             THEN a.hour_of_ems_arrival_at_hospital - a.hour_of_crash
           END                                    AS delay_to_hospital,

  /* person‑level fields */
  /* 12 */ p.age,
  /* 13 */ p.person_type,
  /* 14 */ p.seating_position,

  /* 15 */ CASE p.restraint_system_helmet_use
             WHEN 0 THEN 0
             WHEN 1 THEN 0.33
             WHEN 2 THEN 0.67
             WHEN 3 THEN 1.0
             ELSE 0.5
           END                                    AS restraint,

  /* 16 */ CASE WHEN p.injury_severity = 4 THEN 1 ELSE 0 END          AS survived,

  /* 17 */ CASE WHEN LOWER(v.rollover) LIKE '%no%' THEN 0 ELSE 1 END  AS rollover,
  /* 18 */ CASE WHEN p.air_bag_deployed BETWEEN 1 AND 9 THEN 1 ELSE 0 END AS airbag,
  /* 19 */ CASE WHEN LOWER(p.police_reported_alcohol_involvement) LIKE '%yes%' THEN 1 ELSE 0 END AS alcohol,
  /* 20 */ CASE WHEN LOWER(p.police_reported_drug_involvement)   LIKE '%yes%' THEN 1 ELSE 0 END AS drugs,
  /* 21 */ p.related_factors_person_level1,

  /* vehicle‑level fields */
  /* 22 */ v.travel_speed,
  /* 23 */ CASE WHEN LOWER(v.speeding_related) LIKE '%yes%' THEN 1 ELSE 0 END AS speeding_related,
  /* 24 */ v.extent_of_damage,
  /* 25 */ v.body_type,
  /* 26 */ v.vehicle_removal,

  /* 27 */ CASE WHEN v.manner_of_collision > 11 THEN 11 ELSE v.manner_of_collision END AS manner_of_collision_capped,
  /* 28 */ CASE WHEN v.roadway_surface_condition > 8 THEN 8 ELSE v.roadway_surface_condition END AS roadway_surface_condition_capped,

  /* crash / vehicle harmful‑event indicators */
  /* 29 */ CASE WHEN a.first_harmful_event  < 90 THEN a.first_harmful_event  ELSE 0 END AS first_harmful_event_capped,
  /* 30 */ CASE WHEN v.most_harmful_event  < 90 THEN v.most_harmful_event   ELSE 0 END AS most_harmful_event_capped

FROM  `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015` AS a
JOIN  `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2015`  AS v
  ON  a.state_number      = v.state_number
 AND a.consecutive_number = v.consecutive_number
JOIN  `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`   AS p
  ON  v.state_number      = p.state_number
 AND v.consecutive_number = p.consecutive_number
 AND v.vehicle_number     = p.vehicle_number;