-- Task: For each year from 2010 to 2016, determine the highest monthly number of motor vehicle theft incidents based on records where "primary_type" is 'MOTOR VEHICLE THEFT', extracting months from the "date" column converted from microseconds to timestamp.

WITH monthly_counts AS (
    SELECT
        "year",
        EXTRACT(MONTH FROM TO_TIMESTAMP("date" / 1e6)) AS "month",
        COUNT(*) AS "monthly_thefts"
    FROM
        CHICAGO.CHICAGO_CRIME.CRIME
    WHERE
        "primary_type" = 'MOTOR VEHICLE THEFT'
        AND "year" BETWEEN 2010 AND 2016
    GROUP BY
        "year",
        "month"
)
SELECT
    "year" AS "Year",
    MAX("monthly_thefts") AS "HighestMotorTheftsInOneMonth"
FROM
    monthly_counts
GROUP BY
    "year"
ORDER BY
    "year";