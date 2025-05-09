SELECT MAX(month_incidents) AS "max_motor_vehicle_theft_incidents_in_a_month_2016"
FROM (
    SELECT 
        DATE_PART('month', TO_TIMESTAMP("date" / 1000000)) AS month_num,
        COUNT(*) AS month_incidents
    FROM CHICAGO.CHICAGO_CRIME.CRIME
    WHERE "year" = 2016
      AND "primary_type" = 'MOTOR VEHICLE THEFT'
      AND "date" IS NOT NULL
    GROUP BY DATE_PART('month', TO_TIMESTAMP("date" / 1000000))
) AS monthly_counts;