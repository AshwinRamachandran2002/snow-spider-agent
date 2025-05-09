WITH person_counts AS (
    /* how many (and how many fatally-injured) persons were involved in each crash */
    SELECT
        "consecutive_number",
        COUNT(*)                                                   AS "person_count",
        SUM(CASE WHEN "injury_severity" = 4 THEN 1 ELSE 0 END)     AS "fatal_persons"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.PERSON_2016
    GROUP BY "consecutive_number"
),
vehicle_stats AS (
    /* body-type proxy + average |speed – limit| using only clean speed data        */
    SELECT
        "consecutive_number",
        MIN("body_type")                                           AS "body_type",
        AVG(ABS("travel_speed" - "speed_limit"))                   AS "avg_speed_diff"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.VEHICLE_2016
    WHERE "travel_speed" BETWEEN 0 AND 151        -- discard codes 997/998/999
      AND "speed_limit"  BETWEEN 0 AND 80         -- discard codes 98/99
    GROUP BY "consecutive_number"
)
SELECT
    a."consecutive_number",                         -- optional identifier
    a."state_number",
    v."body_type",
    a."number_of_drunk_drivers",
    a."day_of_week",
    a."hour_of_crash",
    IFF(a."work_zone" <> 'None', 1, 0)              AS "work_zone_flag",
    /* bucketised average speed-difference feature */
    CASE
         WHEN v."avg_speed_diff" < 20 THEN 0
         WHEN v."avg_speed_diff" < 40 THEN 1
         WHEN v."avg_speed_diff" < 60 THEN 2
         WHEN v."avg_speed_diff" < 80 THEN 3
         ELSE 4
    END                                             AS "speed_diff_level",
    /* label : >1 fatal injuries among >1 persons */
    IFF(p."fatal_persons" > 1, 1, 0)                AS "label"
FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.ACCIDENT_2016         a
JOIN person_counts                                                             p
     ON a."consecutive_number" = p."consecutive_number"
    AND p."person_count" > 1                              -- keep only multi-person crashes
JOIN vehicle_stats                                                              v
     ON a."consecutive_number" = v."consecutive_number";