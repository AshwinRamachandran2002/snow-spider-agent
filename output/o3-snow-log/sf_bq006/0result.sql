WITH daily AS (
    SELECT 
        "date" AS day,
        COUNT(*) AS cnt
    FROM AUSTIN.AUSTIN_INCIDENTS.INCIDENTS_2016
    WHERE "descript" ILIKE '%PUBLIC INTOXICATION%'
    GROUP BY "date"
),
z_scores AS (
    SELECT 
        day,
        cnt,
        (cnt - AVG(cnt) OVER ()) / STDDEV_SAMP(cnt) OVER () AS zscore
    FROM daily
)
SELECT 
    TO_CHAR(day, 'YYYY-MM-DD') AS "date"
FROM z_scores
ORDER BY zscore DESC NULLS LAST
LIMIT 1 OFFSET 1;