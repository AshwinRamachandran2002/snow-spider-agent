WITH monthly_thefts AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("date" / 1000000)) AS "month_start"
    FROM CHICAGO.CHICAGO_CRIME.CRIME
    WHERE "year" = 2016
      AND "primary_type" = 'MOTOR VEHICLE THEFT'
),
counts AS (
    SELECT
        "month_start",
        COUNT(*) AS "incidents_in_month"
    FROM monthly_thefts
    GROUP BY "month_start"
)
SELECT
    MAX("incidents_in_month") AS "highest_monthly_incidents_2016"
FROM counts;