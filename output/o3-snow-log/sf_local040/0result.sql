WITH combined AS (
    SELECT
        t."tree_id",
        t."boroname",
        t."zipcode",
        it."Estimate_Median_income",
        it."Estimate_Mean_income"
    FROM MODERN_DATA.MODERN_DATA."TREES"        t
    LEFT JOIN MODERN_DATA.MODERN_DATA."INCOME_TREES" it
           ON t."zipcode" = it."zipcode"
)
SELECT
    "boroname"                                     AS "Borough",
    COUNT(*)                                       AS "Tree_Count",
    ROUND(AVG("Estimate_Mean_income"), 4)          AS "Average_Mean_Income"
FROM combined
WHERE "boroname" IS NOT NULL
  AND "Estimate_Mean_income"  > 0
  AND "Estimate_Median_income" > 0
GROUP BY "boroname"
ORDER BY "Tree_Count" DESC NULLS LAST
LIMIT 3;