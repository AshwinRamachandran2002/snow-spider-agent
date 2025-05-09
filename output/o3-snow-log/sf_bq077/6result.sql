WITH thefts AS (
    SELECT 
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("date" / 1000000)) AS month_start
    FROM CHICAGO.CHICAGO_CRIME.CRIME
    WHERE "primary_type" = 'MOTOR VEHICLE THEFT'
      AND "year" BETWEEN 2010 AND 2016
), monthly_counts AS (
    SELECT 
        YEAR(month_start)            AS "year",
        COUNT(*)                     AS monthly_thefts
    FROM thefts
    GROUP BY "year", month_start
)
SELECT
    "year",
    MAX(monthly_thefts) AS highest_monthly_motor_thefts
FROM monthly_counts
GROUP BY "year"
ORDER BY "year";