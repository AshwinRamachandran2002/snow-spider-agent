WITH persons_per_month AS (
    SELECT
        "month_of_crash",
        COUNT(*)                           AS person_cnt,
        COUNT_IF("injury_severity" = 4)    AS severe_cnt
    FROM NHTSA_TRAFFIC_FATALITIES.NHTSA_TRAFFIC_FATALITIES.PERSON_2015
    WHERE "month_of_crash" BETWEEN 1 AND 8
    GROUP BY "month_of_crash"
), multi_person_months AS (
    SELECT *
    FROM persons_per_month
    WHERE person_cnt > 1
)
SELECT
    COUNT_IF(severe_cnt > 1)                                          AS months_with_multi_severe,
    COUNT(*)                                                          AS total_multi_person_months,
    ROUND(100.0 * COUNT_IF(severe_cnt > 1) / NULLIF(COUNT(*), 0), 4)  AS pct_with_multi_severe
FROM multi_person_months;