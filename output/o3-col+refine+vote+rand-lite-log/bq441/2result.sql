/* -------------------------------------------------------------------------------------------------
   CRITICAL DETAILS ON 2015 FATAL-CRASHES
   ------------------------------------------------
   • Crash–level information  : accident_2015   (alias c)
   • Person–level information : person_2015     (alias p)
   • Vehicle–level information: vehicle_2015    (alias v)

   The query builds three CTEs (crash / person / vehicle) that pre-compute all derived fields
   described in the “Traffic Fatalities Info List 2015”, then joins them to deliver one wide
   record per person-vehicle involved in a 2015 fatal crash.
-------------------------------------------------------------------------------------------------*/
WITH crash AS (   -- ❶  Crash-level block  ------------------------------------------
    SELECT
        consecutive_number,
        county,
        hour_of_crash,
        functional_system,
        type_of_intersection,
        light_condition,
        atmospheric_conditions_1,
        related_factors_crash_level_1         AS related_factors,

        -- delays (NULL when invalid)
        CASE
            WHEN hour_of_arrival_at_scene BETWEEN 0 AND 23
            THEN hour_of_arrival_at_scene - hour_of_crash
        END                                    AS delay_to_scene,

        CASE
            WHEN hour_of_ems_arrival_at_hospital BETWEEN 0 AND 23
            THEN hour_of_ems_arrival_at_hospital - hour_of_crash
        END                                    AS delay_to_hospital
    FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2015`
),

person AS (      -- ❷  Person-level block  ------------------------------------------
    SELECT
        consecutive_number,
        age,
        person_type,
        seating_position,
        related_factors_person_level1,

        -- outcome & protection
        CASE WHEN injury_severity = 4 THEN 1 ELSE 0 END           AS survived,
        CASE
            WHEN restraint_system_helmet_use = 0 THEN 0
            WHEN restraint_system_helmet_use = 1 THEN 0.33
            WHEN restraint_system_helmet_use = 2 THEN 0.67
            WHEN restraint_system_helmet_use = 3 THEN 1.0
            ELSE 0.5
        END                                                       AS restraint,

        -- binary flags
        CASE WHEN LOWER(rollover) = 'no rollover'               THEN 0 ELSE 1 END AS rollover,
        CASE WHEN air_bag_deployed BETWEEN 1 AND 9              THEN 1 ELSE 0 END AS airbag,
        CASE WHEN LOWER(police_reported_alcohol_involvement) LIKE '%yes%' THEN 1 ELSE 0 END AS alcohol,
        CASE WHEN LOWER(police_reported_drug_involvement)   LIKE '%yes%' THEN 1 ELSE 0 END AS drugs
    FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2015`
),

vehicle AS (     -- ❸  Vehicle-level block  -----------------------------------------
    SELECT
        consecutive_number,
        travel_speed,
        body_type,
        extent_of_damage,
        vehicle_removal,

        -- harm & roadway fields (capped / normalised as requested)
        CASE WHEN first_harmful_event  < 90 THEN first_harmful_event  ELSE 0 END AS first_harmful_event,
        CASE WHEN most_harmful_event   < 90 THEN most_harmful_event   ELSE 0 END AS most_harmful_event,
        CASE WHEN SAFE_CAST(manner_of_collision AS INT64)           > 11
             THEN 11 ELSE manner_of_collision END                     AS manner_of_collision,
        CASE WHEN SAFE_CAST(roadway_surface_condition AS INT64)     > 8
             THEN 8  ELSE roadway_surface_condition END              AS roadway_surface_condition,

        -- speeding flag
        CASE WHEN LOWER(speeding_related) LIKE '%yes%' THEN 1 ELSE 0 END AS speeding_related
    FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2015`
)

-- ❹  FINAL SELECT -------------------------------------------------------------------
SELECT
    /* ---- crash-level ---- */
    c.consecutive_number,
    c.county,
    c.type_of_intersection,
    c.light_condition,
    c.atmospheric_conditions_1,
    c.hour_of_crash,
    c.functional_system,
    c.related_factors,
    c.delay_to_scene,
    c.delay_to_hospital,

    /* ---- person-level ---- */
    p.age,
    p.person_type,
    p.seating_position,
    p.restraint,
    p.survived,
    p.rollover,
    p.airbag,
    p.alcohol,
    p.drugs,
    p.related_factors_person_level1,

    /* ---- vehicle-level ---- */
    v.travel_speed,
    v.speeding_related,
    v.extent_of_damage,
    v.body_type,
    v.vehicle_removal,
    v.manner_of_collision,
    v.roadway_surface_condition,
    v.first_harmful_event,
    v.most_harmful_event
FROM crash   AS c
JOIN person  AS p ON p.consecutive_number = c.consecutive_number
LEFT JOIN vehicle AS v ON v.consecutive_number = c.consecutive_number;