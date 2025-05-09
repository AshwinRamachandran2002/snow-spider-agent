WITH crash_stats AS (
    SELECT
        "state_number",
        "consecutive_number",
        COUNT(DISTINCT "person_number")                                          AS "persons_in_crash",
        SUM(CASE WHEN "injury_severity" = 4 THEN 1 ELSE 0 END)                  AS "severe_cnt"
    FROM "NHTSA_TRAFFIC_FATALITIES"."NHTSA_TRAFFIC_FATALITIES"."PERSON_2015"
    WHERE "month_of_crash" BETWEEN 1 AND 8
    GROUP BY "state_number", "consecutive_number"
)
SELECT
    COUNT_IF("persons_in_crash" > 1 AND "severe_cnt" > 1)                         AS "numerator_multi_severe",
    COUNT_IF("persons_in_crash" > 1)                                              AS "denominator_multi_person",
    ROUND(
        100.0 * COUNT_IF("persons_in_crash" > 1 AND "severe_cnt" > 1)
        / NULLIF(COUNT_IF("persons_in_crash" > 1), 0),
        2
    )                                                                             AS "percentage"
FROM crash_stats;