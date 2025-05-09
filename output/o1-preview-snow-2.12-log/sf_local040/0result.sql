SELECT
    t."boroname" AS "Borough",
    COUNT(*) AS "Number_of_Trees",
    ROUND(AVG(i."Estimate_Mean_income"), 4) AS "Average_Mean_Income"
FROM
    "MODERN_DATA"."MODERN_DATA"."TREES" t
JOIN
    "MODERN_DATA"."MODERN_DATA"."INCOME_TREES" i
    ON t."zipcode" = i."zipcode"
WHERE
    t."boroname" IS NOT NULL
    AND t."boroname" != ''
    AND i."Estimate_Median_income" > 0
    AND i."Estimate_Mean_income" > 0
GROUP BY
    t."boroname"
ORDER BY
    COUNT(*) DESC NULLS LAST
LIMIT 3;