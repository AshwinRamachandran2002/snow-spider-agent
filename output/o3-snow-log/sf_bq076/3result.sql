SELECT MAX("month_incidents") AS "max_motor_vehicle_thefts_in_month_2016"
FROM (
    SELECT 
        MONTH(TO_TIMESTAMP("date" / 1000000)) AS "month",
        COUNT(*) AS "month_incidents"
    FROM CHICAGO.CHICAGO_CRIME.CRIME
    WHERE "year" = 2016
      AND "primary_type" = 'MOTOR VEHICLE THEFT'
    GROUP BY MONTH(TO_TIMESTAMP("date" / 1000000))
);