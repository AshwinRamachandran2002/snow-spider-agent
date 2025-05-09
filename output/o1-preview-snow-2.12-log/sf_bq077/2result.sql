SELECT "year", MAX("thefts") AS "HighestMotorTheftsInOneMonth"
FROM (
    SELECT "year", TO_CHAR(TO_TIMESTAMP("date"/1000000), 'MM') AS "month", COUNT(*) AS "thefts"
    FROM "CHICAGO"."CHICAGO_CRIME"."CRIME"
    WHERE "primary_type" = 'MOTOR VEHICLE THEFT' AND "year" BETWEEN 2010 AND 2016
    GROUP BY "year", "month"
) AS sub
GROUP BY "year"
ORDER BY "year";