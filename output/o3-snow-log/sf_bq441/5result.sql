/*  Critical 2015 traffic-accident details
    – one row per PERSON-vehicle record
*/
SELECT
    /* 1-8  Accident-level fields */
    a."consecutive_number"                                  AS "consecutive_number",
    a."county"                                              AS "county",
    a."type_of_intersection"                                AS "type_of_intersection",
    a."light_condition"                                     AS "light_condition",
    a."atmospheric_conditions_1"                            AS "atmospheric_conditions_1",
    a."hour_of_crash"                                       AS "hour_of_crash",
    a."functional_system"                                   AS "functional_system",
    a."related_factors_crash_level_1"                       AS "related_factors",
    
    /* 9-10  Delays (scene / hospital) */
    CASE
        WHEN a."hour_of_ems_arrival_at_hospital" BETWEEN 0 AND 23
        THEN a."hour_of_ems_arrival_at_hospital" - a."hour_of_crash"
    END                                                     AS "delay_to_hospital",
    CASE
        WHEN a."hour_of_arrival_at_scene" BETWEEN 0 AND 23
        THEN a."hour_of_arrival_at_scene" - a."hour_of_crash"
    END                                                     AS "delay_to_scene",
    
    /* 11-14  Person attributes & restraint score */
    p."age"                                                 AS "age",
    p."person_type"                                         AS "person_type",
    p."seating_position"                                    AS "seating_position",
    CASE
        WHEN p."restraint_system_helmet_use" = 0 THEN 0
        WHEN p."restraint_system_helmet_use" = 1 THEN 0.33
        WHEN p."restraint_system_helmet_use" = 2 THEN 0.67
        WHEN p."restraint_system_helmet_use" = 3 THEN 1.00
        ELSE 0.50
    END                                                     AS "restraint",
    
    /* 15-20  Survival / impairment / safety devices */
    CASE WHEN p."injury_severity" = 4 THEN 1 ELSE 0 END     AS "survived",
    CASE WHEN p."rollover" ILIKE 'No%' THEN 0 ELSE 1 END    AS "rollover",
    CASE WHEN p."air_bag_deployed" BETWEEN 1 AND 9 THEN 1 ELSE 0 END AS "airbag",
    CASE WHEN p."police_reported_alcohol_involvement" ILIKE '%Yes%' THEN 1 ELSE 0 END AS "alcohol",
    CASE WHEN p."police_reported_drug_involvement"   ILIKE '%Yes%' THEN 1 ELSE 0 END AS "drugs",
    p."related_factors_person_level1"                       AS "related_factors_person_level1",
    
    /* 21-29  Vehicle attributes & recoded crash details */
    v."travel_speed"                                        AS "travel_speed",
    CASE WHEN v."speeding_related" ILIKE '%Yes%' THEN 1 ELSE 0 END AS "speeding_related",
    v."extent_of_damage"                                    AS "extent_of_damage",
    v."body_type"                                           AS "body_type",
    v."vehicle_removal"                                     AS "vehicle_removal",
    /* cap values >11 */
    CASE 
        WHEN v."manner_of_collision" > 11 THEN 11
        ELSE v."manner_of_collision"
    END                                                     AS "manner_of_collision",
    /* cap values >8  */
    CASE 
        WHEN v."roadway_surface_condition" > 8 THEN 8
        ELSE v."roadway_surface_condition"
    END                                                     AS "roadway_surface_condition",
    /* codes <90 kept, else 0 */
    CASE 
        WHEN v."first_harmful_event" < 90 THEN v."first_harmful_event"
        ELSE 0
    END                                                     AS "first_harmful_event",
    CASE 
        WHEN v."most_harmful_event" < 90 THEN v."most_harmful_event"
        ELSE 0
    END                                                     AS "most_harmful_event"
FROM  NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.PERSON_2015   p
JOIN  NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.VEHICLE_2015  v
      ON p."consecutive_number" = v."consecutive_number"
JOIN  NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2015 a
      ON p."consecutive_number" = a."consecutive_number";