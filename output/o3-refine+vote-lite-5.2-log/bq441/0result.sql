/*  Critical details for 2015 traffic‑fatality crashes                      */
/*  Derived exactly as described in the external “Traffic Fatalities Info” */

/*  Each row = one person involved in a 2015 fatal‑crash (motor‑vehicle     */
/*  occupants as well as non‑motorists).  Primary key = (consecutive_number,*/
/*  person_number).                                                         */

SELECT
    /*  -------------- accident‑level fields -------------- */
    a.consecutive_number,                                   -- unique crash id
    a.county,                                               -- county code
    a.type_of_intersection,                                 -- intersection type
    a.light_condition,                                      -- lighting
    a.atmospheric_conditions_1,                             -- weather
    a.hour_of_crash,                                        -- hour of crash
    a.functional_system,                                    -- roadway class
    a.related_factors_crash_level_1        AS related_factors,
    /*  Time delays (valid only when EMS‑time in [0,23]) */
    CASE
        WHEN a.hour_of_arrival_at_scene BETWEEN 0 AND 23
             AND a.hour_of_crash            BETWEEN 0 AND 23
        THEN a.hour_of_arrival_at_scene - a.hour_of_crash
    END                                   AS delay_to_scene,
    CASE
        WHEN a.hour_of_ems_arrival_at_hospital BETWEEN 0 AND 23
             AND a.hour_of_crash                BETWEEN 0 AND 23
        THEN a.hour_of_ems_arrival_at_hospital - a.hour_of_crash
    END                                   AS delay_to_hospital,

    /*  -------------- person‑level fields -------------- */
    p.person_number,
    p.age,
    p.person_type,
    p.seating_position,
    /*  Restraint score */
    CASE p.restraint_system_helmet_use
        WHEN 0 THEN 0
        WHEN 1 THEN 0.33
        WHEN 2 THEN 0.67
        WHEN 3 THEN 1.0
        ELSE 0.5
    END                                   AS restraint,
    /*  Survived = injury_severity = 4 (Fatal Injury (K) =0, everything else =1) */
    CASE WHEN p.injury_severity = 4 THEN 0 ELSE 1 END       AS survived,
    /*  Air‑bag deployment */
    CASE WHEN p.air_bag_deployed BETWEEN 1 AND 9 THEN 1 ELSE 0 END AS airbag,
    /*  Alcohol / drug involvement (police reported) */
    CASE WHEN p.police_reported_alcohol_involvement LIKE 'Yes%' THEN 1 ELSE 0 END AS alcohol,
    CASE WHEN p.police_reported_drug_involvement    LIKE 'Yes%' THEN 1 ELSE 0 END AS drugs,
    p.related_factors_person_level1,

    /*  -------------- vehicle‑level fields -------------- */
    v.vehicle_number,
    v.travel_speed,
    CASE WHEN v.speeding_related LIKE 'Yes%' THEN 1 ELSE 0 END      AS speeding_related,
    v.body_type,
    v.extent_of_damage,
    v.vehicle_removal,
    /*  Binary rollover flag */
    CASE WHEN v.rollover LIKE 'Rollover%' THEN 1 ELSE 0 END         AS rollover,
    /*  Manner of collision – capped at 11 */
    CASE WHEN v.manner_of_collision > 11 THEN 11
         ELSE v.manner_of_collision
    END                                   AS manner_of_collision,
    /*  Roadway surface condition – capped at 8 for codes >11 */
    CASE WHEN v.roadway_surface_condition > 11 THEN 8
         ELSE v.roadway_surface_condition
    END                                   AS roadway_surface_condition,
    /*  First / Most harmful events (0 when ≥90) */
    CASE WHEN v.first_harmful_event < 90  THEN v.first_harmful_event  ELSE 0 END AS first_harmful_event,
    CASE WHEN v.most_harmful_event  < 90  THEN v.most_harmful_event   ELSE 0 END AS most_harmful_event

FROM
    `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015`        AS a
JOIN
    `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`          AS p
    USING (state_number, consecutive_number)
LEFT JOIN
    `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2015`         AS v
    USING (state_number, consecutive_number, vehicle_number)
;