WITH daily_counts AS (
    SELECT 
        "date" AS incident_date,
        COUNT(*) AS daily_count
    FROM "AUSTIN"."AUSTIN_INCIDENTS"."INCIDENTS_2016"
    WHERE 
        "descript" = 'PUBLIC INTOXICATION'
        AND "date" BETWEEN '2016-01-01' AND '2016-12-31'
    GROUP BY "date"
),
stats AS (
    SELECT
        incident_date,
        daily_count,
        AVG(daily_count)  OVER () AS mean_cnt,
        STDDEV_SAMP(daily_count) OVER () AS std_cnt
    FROM daily_counts
),
z_scores AS (
    SELECT
        incident_date,
        daily_count,
        (daily_count - mean_cnt) / NULLIF(std_cnt, 0) AS z_score
    FROM stats
)
SELECT 
    TO_CHAR(incident_date, 'YYYY-MM-DD') AS "2016_date_with_2nd_highest_z_score"
FROM z_scores
ORDER BY z_score DESC NULLS LAST
LIMIT 1 OFFSET 1;