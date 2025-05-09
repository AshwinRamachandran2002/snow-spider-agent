SELECT 
    LPAD(CAST(EXTRACT(month FROM TO_TIMESTAMP("date" / 1e6)) AS VARCHAR(2)), 2, '0') AS "Month_num",
    TRIM(TO_CHAR(TO_TIMESTAMP("date" / 1e6), 'Month')) AS "Month_name",
    COUNT(*) AS "Number_of_Thefts"
FROM 
    "CHICAGO"."CHICAGO_CRIME"."CRIME"
WHERE 
    "primary_type" = 'MOTOR VEHICLE THEFT' AND "year" = 2016
GROUP BY 
    "Month_num", "Month_name"
ORDER BY 
    "Number_of_Thefts" DESC NULLS LAST
LIMIT 1;