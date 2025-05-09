WITH monthly_counts AS (
    SELECT
        "year",
        MONTH(TO_TIMESTAMP("date" / 1000000)) AS "month",
        COUNT(*) AS "motor_theft_count"
    FROM CHICAGO.CHICAGO_CRIME.CRIME
    WHERE "primary_type" = 'MOTOR VEHICLE THEFT'
      AND "year" BETWEEN 2010 AND 2016
    GROUP BY "year", MONTH(TO_TIMESTAMP("date" / 1000000))
),
yearly_max AS (
    SELECT
        "year",
        MAX("motor_theft_count") AS "highest_monthly_motor_thefts"
    FROM monthly_counts
    GROUP BY "year"
)
SELECT
    "year",
    "highest_monthly_motor_thefts"
FROM yearly_max
ORDER BY "year" NULLS LAST;