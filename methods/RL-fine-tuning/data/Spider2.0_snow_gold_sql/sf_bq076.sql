SELECT
    TO_CHAR(TO_TIMESTAMP_NTZ("date"/1000000), 'MM') AS "Month_num",
    TO_CHAR(TO_TIMESTAMP_NTZ("date"/1000000), 'Month') AS "Month_name",
    COUNT(*) AS "Number_of_Thefts"
FROM CHICAGO.CHICAGO_CRIME.CRIME
WHERE "primary_type" = 'MOTOR VEHICLE THEFT' AND "year" = 2016
GROUP BY "Month_num", "Month_name"
ORDER BY "Number_of_Thefts" DESC NULLS LAST
LIMIT 1;