-- Task: Identify the date in 2016 with the second highest Z-score for the daily count of incidents where "descript" equals 'PUBLIC INTOXICATION', based on the distribution of daily incident counts throughout the year. Report the date in the format '2016-xx-xx'.
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