SELECT 
    t."boroname" AS "Borough", 
    COUNT(*) AS "Number_of_Trees", 
    AVG(i."Estimate_Mean_income") AS "Average_Mean_Income"
FROM "MODERN_DATA"."MODERN_DATA"."TREES" t
JOIN "MODERN_DATA"."MODERN_DATA"."INCOME_TREES" i
    ON t."zipcode" = i."zipcode"
WHERE 
    i."Estimate_Median_income" > 0
    AND i."Estimate_Mean_income" > 0
    AND t."boroname" IS NOT NULL
    AND TRIM(t."boroname") != ''
GROUP BY t."boroname"
ORDER BY COUNT(*) DESC NULLS LAST
LIMIT 3;