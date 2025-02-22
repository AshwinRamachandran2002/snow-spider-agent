-- Task: List the number of motor vehicle theft incidents per month during 2016.
SELECT
    EXTRACT(MONTH FROM date) AS month,
    COUNT(1) AS incidents
FROM
    `bigquery-public-data.chicago_crime.crime`
WHERE
    primary_type = 'MOTOR VEHICLE THEFT'
    AND year = 2016
GROUP BY
    month
ORDER BY
    month;