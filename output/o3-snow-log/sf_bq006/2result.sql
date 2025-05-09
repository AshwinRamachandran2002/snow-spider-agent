WITH daily_counts AS (
    SELECT
        "date",
        COUNT(*) AS cnt
    FROM AUSTIN.AUSTIN_INCIDENTS.INCIDENTS_2016
    WHERE TRIM(UPPER("descript")) = 'PUBLIC INTOXICATION'
      AND EXTRACT(year FROM "date") = 2016
    GROUP BY "date"
),
stats AS (
    SELECT
        AVG(cnt)  AS mean_cnt,
        STDDEV_SAMP(cnt) AS std_cnt
    FROM daily_counts
),
zscores AS (
    SELECT
        dc."date",
        (dc.cnt - s.mean_cnt) / s.std_cnt AS zscore
    FROM daily_counts dc
    CROSS JOIN stats s
)
SELECT TO_CHAR("date", 'YYYY-MM-DD') AS "date"
FROM (
    SELECT
        "date",
        zscore,
        ROW_NUMBER() OVER (ORDER BY zscore DESC NULLS LAST) AS rn
    FROM zscores
)
WHERE rn = 2;