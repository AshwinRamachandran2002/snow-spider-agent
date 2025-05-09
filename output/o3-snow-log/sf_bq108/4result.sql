WITH multi_person_crashes AS (
    SELECT
        "state_number",
        "consecutive_number",
        SUM(CASE WHEN "injury_severity" = 4 THEN 1 ELSE 0 END) AS "severe_injury_count"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES."PERSON_2015"
    WHERE "month_of_crash" BETWEEN 1 AND 8
    GROUP BY "state_number", "consecutive_number"
    HAVING COUNT(DISTINCT "person_number") > 1          -- accidents with > 1 person
)
SELECT
    ROUND(
        100.0 * SUM(CASE WHEN "severe_injury_count" > 1 THEN 1 ELSE 0 END)
              / NULLIF(COUNT(*), 0),
        4
    ) AS "percent_multi_person_crashes_with_multi_severe_injuries"
FROM multi_person_crashes;