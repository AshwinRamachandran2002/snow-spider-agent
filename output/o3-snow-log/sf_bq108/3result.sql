WITH per_crash AS (
    /* 1.  Aggregate each crash (state_number + consecutive_number) occurring Jan–Aug 2015 */
    SELECT
        "state_number",
        "consecutive_number",
        COUNT(DISTINCT "person_number")                                        AS "persons_in_crash",
        SUM(CASE WHEN "injury_severity" = 4 THEN 1 ELSE 0 END)                AS "severe_inj_cnt"
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.PERSON_2015
    WHERE "month_of_crash" BETWEEN 1 AND 8
    GROUP BY "state_number", "consecutive_number"
)
/* 2.  Among multi-person crashes, calculate the share that also had >1 severely-injured person */
SELECT
    ( SUM( CASE WHEN "severe_inj_cnt" > 1 THEN 1 ELSE 0 END ) * 100.0
      / NULLIF( COUNT(*), 0 ) )            AS "pct_multi_severe"
FROM per_crash
WHERE "persons_in_crash" > 1;