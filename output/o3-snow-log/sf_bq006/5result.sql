WITH daily_counts AS (
    SELECT
        "date" AS incident_date,
        COUNT(*) AS cnt
    FROM "AUSTIN"."AUSTIN_INCIDENTS"."INCIDENTS_2016"
    WHERE "descript" ILIKE '%PUBLIC INTOXICATION%'
    GROUP BY "date"
),

stats AS (
    SELECT
        AVG(cnt)  AS mean_cnt,
        STDDEV_SAMP(cnt) AS std_cnt
    FROM daily_counts
),

z_scores AS (
    SELECT
        d.incident_date,
        d.cnt,
        (d.cnt - s.mean_cnt) / s.std_cnt AS z_score
    FROM daily_counts d
    CROSS JOIN stats s
)

SELECT
    TO_CHAR(incident_date, 'YYYY-MM-DD') AS "date"
FROM z_scores
ORDER BY z_score DESC NULLS LAST, incident_date
OFFSET 1 ROW           -- skip the highest; get the second highest
FETCH NEXT 1 ROW ONLY;