SELECT
    /*  1 */ a.`consecutive_number`,
    /*  2 */ a.`county`,
    /*  3 */ a.`type_of_intersection`,
    /*  4 */ a.`light_condition`,
    /*  5 */ a.`atmospheric_conditions_1`,
    /*  6 */ a.`hour_of_crash`,
    /*  7 */ a.`functional_system`,
    /*  8 */ a.`related_factors_crash_level_1`        AS related_factors,
    /*  9 */ CASE
               WHEN a.`hour_of_ems_arrival_at_hospital` BETWEEN 0 AND 23
               THEN a.`hour_of_ems_arrival_at_hospital` - a.`hour_of_crash`
             END                                       AS delay_to_hospital,
    /* 10 */ CASE
               WHEN a.`hour_of_arrival_at_scene` BETWEEN 0 AND 23
               THEN a.`hour_of_arrival_at_scene` - a.`hour_of_crash`
             END                                       AS delay_to_scene,

    /* 11 */ p.`age`,
    /* 12 */ p.`person_type`,
    /* 13 */ p.`seating_position`,
    /* 14 */ CASE
               WHEN p.`restraint_system_helmet_use` = 0 THEN 0
               WHEN p.`restraint_system_helmet_use` = 1 THEN 0.33
               WHEN p.`restraint_system_helmet_use` = 2 THEN 0.67
               WHEN p.`restraint_system_helmet_use` = 3 THEN 1.00
               ELSE 0.50
             END                                       AS restraint,
    /* 15 */ CASE WHEN p.`injury_severity` = 4 THEN 1 ELSE 0 END AS survived,
    /* 16 */ CASE WHEN v.`rollover` = 'No Rollover' THEN 0 ELSE 1 END AS rollover,
    /* 17 */ CASE WHEN p.`air_bag_deployed` BETWEEN 1 AND 9 THEN 1 ELSE 0 END AS airbag,
    /* 18 */ CASE
               WHEN LOWER(p.`police_reported_alcohol_involvement`) LIKE '%yes%' THEN 1
               ELSE 0
             END                                       AS alcohol,
    /* 19 */ CASE
               WHEN LOWER(p.`police_reported_drug_involvement`) LIKE '%yes%' THEN 1
               ELSE 0
             END                                       AS drugs,
    /* 20 */ p.`related_factors_person_level1`,
    /* 21 */ v.`travel_speed`,
    /* 22 */ CASE
               WHEN LOWER(v.`speeding_related`) LIKE '%yes%' THEN 1
               ELSE 0
             END                                       AS speeding_related,
    /* 23 */ v.`extent_of_damage`,
    /* 24 */ v.`body_type`,
    /* 25 */ v.`vehicle_removal`,
    /* 26 */ CASE
               WHEN v.`manner_of_collision` > 11 THEN 11
               ELSE v.`manner_of_collision`
             END                                       AS manner_of_collision,
    /* 27 */ CASE
               WHEN v.`roadway_surface_condition` > 8 THEN 8
               ELSE v.`roadway_surface_condition`
             END                                       AS roadway_surface_condition,
    /* 28 */ CASE
               WHEN v.`first_harmful_event` < 90 THEN v.`first_harmful_event`
               ELSE 0
             END                                       AS first_harmful_event,
    /* 29 */ CASE
               WHEN v.`most_harmful_event` < 90 THEN v.`most_harmful_event`
               ELSE 0
             END                                       AS most_harmful_event
FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015` AS a
LEFT JOIN `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`  AS p
       ON a.`consecutive_number` = p.`consecutive_number`
LEFT JOIN `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2015` AS v
       ON a.`consecutive_number` = v.`consecutive_number`;