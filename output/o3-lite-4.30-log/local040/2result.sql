SELECT 
    borough,
    ROUND(avg_mean_income, 4) AS average_mean_income
FROM (
    SELECT
        t."boroname"                          AS borough,
        COUNT(*)                              AS tree_count,
        AVG(i."Estimate_Mean_income")         AS avg_mean_income
    FROM "trees"        AS t
    JOIN "income_trees" AS i
      ON t."zipcode" = i."zipcode"
    WHERE t."boroname" IS NOT NULL
      AND i."Estimate_Median_income" > 0
      AND i."Estimate_Mean_income"  > 0
    GROUP BY t."boroname"
) 
ORDER BY tree_count DESC
LIMIT 3;