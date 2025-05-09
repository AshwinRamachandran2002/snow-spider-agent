WITH daily_counts AS (
    SELECT
        "date" AS incident_date,
        COUNT(*) AS daily_total
    FROM AUSTIN.AUSTIN_INCIDENTS.INCIDENTS_2016
    WHERE YEAR("date") = 2016
      AND "descript" ILIKE '%PUBLIC INTOXICATION%'
    GROUP BY "date"
),
stats AS (
    SELECT
        AVG(daily_total) AS mean_cnt,
        STDDEV_POP(daily_total) AS std_cnt
    FROM daily_counts
),
z_scores AS (
    SELECT
        incident_date,
        daily_total,
        (daily_total - stats.mean_cnt) / NULLIF(stats.std_cnt, 0) AS z_score
    FROM daily_counts
    CROSS JOIN stats
)
SELECT
    TO_CHAR(incident_date, 'YYYY-MM-DD') AS "2016_date_with_second_highest_z_score"
FROM z_scores
ORDER BY z_score DESC NULLS LAST
OFFSET 1 ROW
FETCH NEXT 1 ROW ONLY;