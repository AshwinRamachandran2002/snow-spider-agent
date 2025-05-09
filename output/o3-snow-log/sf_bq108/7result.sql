WITH jan_aug AS (
    SELECT 
        "state_number",
        "consecutive_number",
        "person_number",
        "injury_severity"
    FROM "NHTSA_TRAFFIC_FATALITIES"."NHTSA_TRAFFIC_FATALITIES"."PERSON_2015"
    WHERE "month_of_crash" BETWEEN 1 AND 8
),
crash_rollup AS (
    SELECT
        "state_number",
        "consecutive_number",
        COUNT(DISTINCT "person_number")                                   AS n_persons,
        COUNT(CASE WHEN "injury_severity" = 4 THEN 1 END)                AS n_severe
    FROM jan_aug
    GROUP BY "state_number", "consecutive_number"
),
summary AS (
    SELECT
        COUNT_IF(n_persons > 1 AND n_severe > 1)  AS numerator_crashes,
        COUNT_IF(n_persons > 1)                   AS denominator_crashes
    FROM crash_rollup
)
SELECT 
    ROUND(
        100.0 * numerator_crashes / NULLIF(denominator_crashes, 0),
        4
    ) AS "percentage_with_multi_severe"
FROM summary;