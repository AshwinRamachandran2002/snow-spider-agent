WITH TreeCounts AS (
    SELECT "boroname", COUNT(*) AS "tree_count"
    FROM "trees"
    GROUP BY "boroname"
),
AverageIncomes AS (
    SELECT t."boroname", AVG(i."Estimate_Mean_income") AS "average_mean_income"
    FROM "trees" t
    JOIN "income_trees" i ON t."zipcode" = i."zipcode"
    WHERE i."Estimate_Mean_income" > 0 AND i."Estimate_Median_income" > 0
    GROUP BY t."boroname"
)
SELECT 
    tc."boroname" AS "Borough",
    tc."tree_count" AS "Trees_Count",
    ai."average_mean_income" AS "Average_Mean_Income"
FROM TreeCounts tc
LEFT JOIN AverageIncomes ai ON tc."boroname" = ai."boroname"
ORDER BY tc."tree_count" DESC
LIMIT 3;