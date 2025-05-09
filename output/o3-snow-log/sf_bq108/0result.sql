WITH crash_summary AS (
    SELECT
        "state_number",
        "consecutive_number",
        COUNT(DISTINCT "person_number")                                                    AS "num_persons",
        SUM(CASE WHEN "injury_severity" = 4 THEN 1 ELSE 0 END)                             AS "num_severe"
    FROM
        NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.PERSON_2015
    WHERE
        "month_of_crash" BETWEEN 1 AND 8
    GROUP BY
        "state_number",
        "consecutive_number"
    HAVING
        COUNT(DISTINCT "person_number") > 1              -- multi-person crashes
)
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN "num_severe" > 1 THEN 1 ELSE 0 END) / COUNT(*),
        2
    ) AS "pct_multi_person_crashes_with_multiple_severe_injuries"
FROM
    crash_summary;