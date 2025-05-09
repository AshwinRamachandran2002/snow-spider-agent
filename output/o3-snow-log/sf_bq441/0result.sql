SELECT
    p."consecutive_number",

    /* ---------- crash-level attributes (where / when / conditions) ---------- */
    a."county",
    a."type_of_intersection",
    a."light_condition",
    a."atmospheric_conditions_1"                                AS "atmospheric_conditions",
    a."hour_of_crash",
    a."functional_system",
    a."related_factors_crash_level_1"                           AS "related_factors",

    /* ---------- EMS time lags ---------- */
    CASE
        WHEN a."hour_of_ems_arrival_at_hospital" BETWEEN 0 AND 23
        THEN a."hour_of_ems_arrival_at_hospital" - a."hour_of_crash"
    END                                                         AS "delay_to_hospital",
    CASE
        WHEN a."hour_of_arrival_at_scene" BETWEEN 0 AND 23
        THEN a."hour_of_arrival_at_scene" - a."hour_of_crash"
    END                                                         AS "delay_to_scene",

    /* ---------- person-level attributes ---------- */
    p."age",
    p."person_type",
    p."seating_position",
    /* restraint score */
    CASE
        WHEN p."restraint_system_helmet_use" = 0 THEN 0
        WHEN p."restraint_system_helmet_use" = 1 THEN 0.33
        WHEN p."restraint_system_helmet_use" = 2 THEN 0.67
        WHEN p."restraint_system_helmet_use" = 3 THEN 1.0
        ELSE 0.5
    END                                                         AS "restraint",
    /* survival flag */
    CASE WHEN p."injury_severity" = 4 THEN 1 ELSE 0 END         AS "survived",
    /* rollover flag */
    CASE
        WHEN p."rollover" ILIKE '%No Rollover%' THEN 0
        WHEN p."rollover" IS NULL                               THEN NULL
        ELSE 1
    END                                                         AS "rollover",
    /* airbag deployed flag */
    CASE WHEN p."air_bag_deployed" BETWEEN 1 AND 9 THEN 1 ELSE 0 END AS "airbag",
    /* alcohol / drug flags */
    CASE WHEN p."police_reported_alcohol_involvement" ILIKE '%Yes%' THEN 1 ELSE 0 END AS "alcohol",
    CASE WHEN p."police_reported_drug_involvement"   ILIKE '%Yes%' THEN 1 ELSE 0 END AS "drugs",
    p."related_factors_person_level1",

    /* ---------- vehicle-level attributes ---------- */
    v."travel_speed",
    CASE WHEN v."speeding_related" ILIKE '%Yes%' THEN 1 ELSE 0 END AS "speeding_related",
    v."extent_of_damage",
    v."body_type",
    v."vehicle_removal",
    /* capped manner of collision (<=11) */
    CASE
        WHEN v."manner_of_collision" > 11 THEN 11
        ELSE v."manner_of_collision"
    END                                                         AS "manner_of_collision",
    /* capped roadway surface condition (values >11 -> 8) */
    CASE
        WHEN v."roadway_surface_condition" > 11 THEN 8
        ELSE v."roadway_surface_condition"
    END                                                         AS "roadway_surface_condition",
    /* first / most harmful events (values >=90 -> 0) */
    CASE
        WHEN v."first_harmful_event" < 90 THEN v."first_harmful_event"
        ELSE 0
    END                                                         AS "first_harmful_event",
    CASE
        WHEN v."most_harmful_event"  < 90 THEN v."most_harmful_event"
        ELSE 0
    END                                                         AS "most_harmful_event"

FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.PERSON_2015   AS p
LEFT JOIN NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2015 AS a
       ON p."consecutive_number" = a."consecutive_number"
LEFT JOIN NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.VEHICLE_2015  AS v
       ON p."consecutive_number" = v."consecutive_number";