SELECT "year", MAX(monthly_count) AS "HighestMotorTheftsInOneMonth"
FROM (
    SELECT "year", 
           EXTRACT(MONTH FROM TO_TIMESTAMP_LTZ("date"/1000000)) AS "month", 
           COUNT(*) AS monthly_count
    FROM CHICAGO.CHICAGO_CRIME.CRIME
    WHERE "primary_type" = 'MOTOR VEHICLE THEFT' AND "year" BETWEEN 2010 AND 2016
    GROUP BY "year", "month"
)
GROUP BY "year"
ORDER BY "year";