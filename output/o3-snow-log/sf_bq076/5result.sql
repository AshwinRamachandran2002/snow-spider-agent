SELECT MAX("month_count") AS "highest_incidents"
FROM (
    SELECT EXTRACT(MONTH FROM TO_TIMESTAMP("date" / 1000000)) AS "month",
           COUNT(*) AS "month_count"
    FROM CHICAGO.CHICAGO_CRIME."CRIME"
    WHERE "year" = 2016
      AND "primary_type" = 'MOTOR VEHICLE THEFT'
    GROUP BY "month"
);