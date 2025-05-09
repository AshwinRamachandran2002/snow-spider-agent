WITH daily_counts AS (
    SELECT
        "date",
        COUNT(*) AS "incident_count"
    FROM
        AUSTIN.AUSTIN_INCIDENTS.INCIDENTS_2016
    WHERE
        "descript" = 'PUBLIC INTOXICATION'
    GROUP BY
        "date"
),
stats AS (
    SELECT
        AVG("incident_count") AS "mean_incidents",
        STDDEV_SAMP("incident_count") AS "stddev_incidents"
    FROM
        daily_counts
),
z_scores AS (
    SELECT
        d."date",
        d."incident_count",
        ROUND((d."incident_count" - s."mean_incidents") / s."stddev_incidents", 4) AS "z_score"
    FROM
        daily_counts d
    CROSS JOIN
        stats s
)
SELECT
    "date"
FROM
    z_scores
ORDER BY
    "z_score" DESC NULLS LAST,
    "date" ASC
LIMIT 1 OFFSET 1;