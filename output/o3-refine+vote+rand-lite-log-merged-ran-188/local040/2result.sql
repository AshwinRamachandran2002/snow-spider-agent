WITH joined AS (
    SELECT 
        t."boroname",
        it."Estimate_Mean_income"
    FROM "trees" AS t
    LEFT JOIN "income_trees" AS it
           ON t."zipcode" = it."zipcode"
    WHERE t."boroname" IS NOT NULL
      AND t."boroname" <> ''
      AND it."Estimate_Median_income" > 0
      AND it."Estimate_Mean_income"  > 0
)
SELECT 
    boroname,
    COUNT(*)                           AS tree_count,
    AVG(Estimate_Mean_income)          AS avg_mean_income
FROM joined
GROUP BY boroname
ORDER BY tree_count DESC
LIMIT 3;