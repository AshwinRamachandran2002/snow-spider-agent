SELECT 
    MAX("month_count") AS "max_motor_vehicle_thefts_in_2016_single_month"
FROM (
    SELECT 
        EXTRACT(MONTH FROM TO_TIMESTAMP("date" / 1000000)) AS "month",
        COUNT(*) AS "month_count"
    FROM CHICAGO.CHICAGO_CRIME.CRIME
    WHERE "primary_type" = 'MOTOR VEHICLE THEFT'
      AND "year" = 2016
    GROUP BY "month"
);