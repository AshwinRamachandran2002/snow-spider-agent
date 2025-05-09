WITH motor_thefts AS (
    SELECT 
        "year"                                                          AS "year",
        EXTRACT(month FROM TO_TIMESTAMP_NTZ("date" / 1000000))          AS "month"
    FROM CHICAGO.CHICAGO_CRIME.CRIME
    WHERE "primary_type" = 'MOTOR VEHICLE THEFT'
      AND "year" BETWEEN 2010 AND 2016
), monthly_counts AS (
    SELECT 
        "year",
        "month",
        COUNT(*)                                                       AS "monthly_motor_thefts"
    FROM motor_thefts
    GROUP BY "year", "month"
), yearly_max AS (
    SELECT
        "year",
        MAX("monthly_motor_thefts")                                    AS "highest_motor_thefts_in_a_month"
    FROM monthly_counts
    GROUP BY "year"
)
SELECT 
    "year",
    "highest_motor_thefts_in_a_month"
FROM yearly_max
ORDER BY "year";