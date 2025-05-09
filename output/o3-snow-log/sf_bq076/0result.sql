SELECT MAX("incidents") AS "max_monthly_motor_vehicle_theft_2016"
FROM (
    SELECT 
        EXTRACT(MONTH FROM TO_TIMESTAMP("date" / 1000000)) AS "month",
        COUNT(*) AS "incidents"
    FROM CHICAGO.CHICAGO_CRIME.CRIME
    WHERE "year" = 2016
      AND "primary_type" = 'MOTOR VEHICLE THEFT'
    GROUP BY "month"
);