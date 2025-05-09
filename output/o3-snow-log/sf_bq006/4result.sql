WITH public_intox AS (
    SELECT
        "date"::DATE AS incident_date
    FROM AUSTIN.AUSTIN_INCIDENTS.INCIDENTS_2016
    WHERE UPPER("descript") = 'PUBLIC INTOXICATION'
),
daily_counts AS (
    SELECT
        incident_date,
        COUNT(*) AS daily_count
    FROM public_intox
    GROUP BY incident_date
),
stats AS (
    SELECT
        AVG(daily_count)  AS mean_cnt,
        STDDEV_SAMP(daily_count) AS stddev_cnt
    FROM daily_counts
),
z_scores AS (
    SELECT
        d.incident_date,
        (d.daily_count - s.mean_cnt) / s.stddev_cnt AS z_score
    FROM daily_counts d
    CROSS JOIN stats s
)
SELECT
    TO_CHAR(incident_date, 'YYYY-MM-DD') AS "2016_date_with_second_highest_z_score"
FROM z_scores
ORDER BY z_score DESC NULLS LAST
OFFSET 1 ROW
FETCH 1 ROW ONLY;