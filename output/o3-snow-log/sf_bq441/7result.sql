/*  Critical accident-level, vehicle-level, and person-level details for all 2015 crashes  */

SELECT
    /* ---- Crash / environment ------------------------------------------------------------ */
    acc."consecutive_number",
    acc."county",
    acc."type_of_intersection",
    acc."light_condition",
    acc."atmospheric_conditions_1",
    acc."hour_of_crash",
    acc."functional_system",
    acc."related_factors_crash_level_1"                         AS "related_factors",

    /*  Delay metrics  */
    CASE 
        WHEN acc."hour_of_arrival_at_scene" BETWEEN 0 AND 23
        THEN acc."hour_of_arrival_at_scene" - acc."hour_of_crash"
    END                                                       AS "delay_to_scene",
    CASE 
        WHEN acc."hour_of_ems_arrival_at_hospital" BETWEEN 0 AND 23
        THEN acc."hour_of_ems_arrival_at_hospital" - acc."hour_of_crash"
    END                                                       AS "delay_to_hospital",

    /* ---- Person details ----------------------------------------------------------------- */
    per."age",
    per."person_type",
    per."seating_position",

    /*  Computed restraint score  */
    CASE
        WHEN per."restraint_system_helmet_use" = 0 THEN 0
        WHEN per."restraint_system_helmet_use" = 1 THEN 0.33
        WHEN per."restraint_system_helmet_use" = 2 THEN 0.67
        WHEN per."restraint_system_helmet_use" = 3 THEN 1.0
        ELSE 0.5
    END                                                       AS "restraint",

    /*  Survival flag (1 = survived, 0 = fatal)  */
    CASE WHEN per."injury_severity" = 4 THEN 1 ELSE 0 END     AS "survived",

    /*  Air-bag deployment  */
    CASE 
        WHEN per."air_bag_deployed" BETWEEN 1 AND 9 THEN 1 ELSE 0 
    END                                                       AS "airbag",

    /*  Alcohol / drug involvement flags  */
    CASE 
        WHEN per."police_reported_alcohol_involvement" ILIKE '%Yes%' THEN 1 
        ELSE 0 
    END                                                       AS "alcohol",
    CASE 
        WHEN per."police_reported_drug_involvement"   ILIKE '%Yes%' THEN 1 
        ELSE 0 
    END                                                       AS "drugs",

    per."related_factors_person_level1",

    /* ---- Vehicle details ---------------------------------------------------------------- */
    /*  Rollover flag  */
    CASE 
        WHEN veh."rollover" = 'No Rollover' THEN 0 ELSE 1 
    END                                                       AS "rollover",

    veh."travel_speed",

    /*  Speeding related flag  */
    CASE 
        WHEN veh."speeding_related" ILIKE '%Yes%' THEN 1 ELSE 0 
    END                                                       AS "speeding_flag",

    veh."extent_of_damage",
    veh."body_type",
    veh."vehicle_removal",

    /*  Manner of collision (capped at 11)  */
    CASE 
        WHEN veh."manner_of_collision" IS NULL                THEN NULL
        WHEN veh."manner_of_collision" <= 11                  THEN veh."manner_of_collision"
        ELSE 11
    END                                                       AS "manner_of_collision",

    /*  Roadway surface condition (capped at 8)  */
    CASE 
        WHEN veh."roadway_surface_condition" IS NULL          THEN NULL
        WHEN veh."roadway_surface_condition" <= 8             THEN veh."roadway_surface_condition"
        ELSE 8
    END                                                       AS "roadway_surface_condition",

    /*  First / most harmful events (values ≥90 → 0)  */
    CASE 
        WHEN veh."first_harmful_event"  < 90 THEN veh."first_harmful_event"  ELSE 0 
    END                                                       AS "first_harmful_event",
    CASE 
        WHEN veh."most_harmful_event"   < 90 THEN veh."most_harmful_event"   ELSE 0 
    END                                                       AS "most_harmful_event"

FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2015  acc
JOIN NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.PERSON_2015    per
  ON acc."consecutive_number" = per."consecutive_number"
JOIN NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.VEHICLE_2015   veh
  ON acc."consecutive_number" = veh."consecutive_number";