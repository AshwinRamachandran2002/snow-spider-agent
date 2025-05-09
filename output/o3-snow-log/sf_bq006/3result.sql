WITH daily_counts AS (
    SELECT 
        "date" AS incident_date,
        COUNT(*) AS count_per_day
    FROM AUSTIN.AUSTIN_INCIDENTS.INCIDENTS_2016
    WHERE "descript" = 'PUBLIC INTOXICATION'
      AND "date" IS NOT NULL
      AND TO_CHAR("date", 'YYYY') = '2016'
    GROUP BY "date"
),
stats AS (
    SELECT 
        AVG(count_per_day)  AS mean_cnt,
        STDDEV_POP(count_per_day) AS stddev_cnt
    FROM daily_counts
),
z_scores AS (
    SELECT
        incident_date,
        (count_per_day - stats.mean_cnt) / NULLIF(stats.stddev_cnt, 0) AS z_score
    FROM daily_counts, stats
)
SELECT 
    TO_CHAR(incident_date, 'YYYY-MM-DD') AS "2016-date"
FROM (
    SELECT 
        incident_date,
        z_score,
        ROW_NUMBER() OVER (ORDER BY z_score DESC NULLS LAST) AS rn
    FROM z_scores
)
WHERE rn = 2;