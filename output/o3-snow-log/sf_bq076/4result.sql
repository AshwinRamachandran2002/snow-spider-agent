WITH monthly_counts AS (
    SELECT
        DATE_TRUNC('month', TO_TIMESTAMP_NTZ("date" / 1000000)) AS "month_start",
        COUNT(*) AS "incident_count"
    FROM CHICAGO.CHICAGO_CRIME.CRIME
    WHERE "year" = 2016
      AND "primary_type" = 'MOTOR VEHICLE THEFT'
    GROUP BY "month_start"
)
SELECT MAX("incident_count") AS "max_incidents_in_a_month_2016"
FROM monthly_counts;