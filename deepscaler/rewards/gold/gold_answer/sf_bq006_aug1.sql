-- Task: What is the date with the highest number of 'PUBLIC INTOXICATION' incidents in Austin for the year 2016?
SELECT
    "date"
FROM
    (
        SELECT
            "date",
            COUNT(*) AS "incident_count"
        FROM
            AUSTIN.AUSTIN_INCIDENTS.INCIDENTS_2016
        WHERE
            "descript" = 'PUBLIC INTOXICATION'
        GROUP BY
            "date"
    ) AS daily_counts
ORDER BY
    "incident_count" DESC,
    "date" ASC
LIMIT 1;