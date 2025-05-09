WITH monthly_counts AS (
    SELECT
        "year",
        MONTH(TO_TIMESTAMP_NTZ("date" / 1000000)) AS "month",
        COUNT(*) AS "monthly_motor_thefts"
    FROM CHICAGO.CHICAGO_CRIME.CRIME
    WHERE
        "year" BETWEEN 2010 AND 2016
        AND "primary_type" = 'MOTOR VEHICLE THEFT'
    GROUP BY
        "year",
        MONTH(TO_TIMESTAMP_NTZ("date" / 1000000))
)
SELECT
    "year",
    MAX("monthly_motor_thefts") AS "highest_motor_thefts_in_one_month"
FROM monthly_counts
GROUP BY
    "year"
ORDER BY
    "year";