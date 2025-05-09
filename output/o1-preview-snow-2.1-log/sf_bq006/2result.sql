WITH daily_counts AS (
    SELECT
        "date",
        COUNT("unique_key") AS "daily_count"
    FROM
        "AUSTIN"."AUSTIN_INCIDENTS"."INCIDENTS_2016"
    WHERE
        "descript" = 'PUBLIC INTOXICATION'
    GROUP BY
        "date"
),
stats AS (
    SELECT
        AVG("daily_count") AS "mean_count",
        STDDEV("daily_count") AS "stddev_count"
    FROM
        daily_counts
),
z_scores AS (
    SELECT
        d."date",
        d."daily_count",
        ROUND((d."daily_count" - s."mean_count") / s."stddev_count", 4) AS "z_score"
    FROM
        daily_counts d, stats s
)
SELECT
    z."date"
FROM
    z_scores z
ORDER BY
    z."z_score" DESC NULLS LAST
LIMIT 1 OFFSET 1;