-- Task: For each month and year between 2010 and 2016, what is the number of motor vehicle thefts?
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
ORDER BY
    "year",
    "month";