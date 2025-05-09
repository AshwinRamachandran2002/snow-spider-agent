SELECT MAX("monthly_incidents") AS "highest_monthly_incidents_2016"
FROM (
    SELECT COUNT(*) AS "monthly_incidents"
    FROM CHICAGO.CHICAGO_CRIME.CRIME
    WHERE "primary_type" = 'MOTOR VEHICLE THEFT'
      AND "year" = 2016
    GROUP BY DATE_TRUNC('month', TO_TIMESTAMP("date", 6))
) AS monthly_counts;