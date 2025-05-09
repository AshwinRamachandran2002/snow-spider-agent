WITH monthly_counts AS (
    SELECT
        "year",
        MONTH(TO_TIMESTAMP_NTZ("date" / 1000000)) AS month_num,
        COUNT(*) AS thefts_in_month
    FROM CHICAGO.CHICAGO_CRIME.CRIME
    WHERE "primary_type" = 'MOTOR VEHICLE THEFT'
      AND "year" BETWEEN 2010 AND 2016
    GROUP BY "year", month_num
)
SELECT
    "year",
    MAX(thefts_in_month) AS highest_monthly_motor_thefts
FROM monthly_counts
GROUP BY "year"
ORDER BY "year";