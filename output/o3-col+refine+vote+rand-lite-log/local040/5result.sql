WITH borough_stats AS (
    SELECT
        t."boroname",
        COUNT(*)                               AS tree_cnt,
        AVG(i."Estimate_Mean_income")          AS avg_mean_income
    FROM "trees" AS t
    JOIN "income_trees" AS i
      ON t."zipcode" = i."zipcode"
    WHERE i."Estimate_Mean_income"   > 0
      AND i."Estimate_Median_income" > 0
      AND t."boroname" IS NOT NULL
    GROUP BY t."boroname"
)
SELECT
    "boroname",
    ROUND(avg_mean_income, 4) AS avg_mean_income
FROM borough_stats
ORDER BY tree_cnt DESC
LIMIT 3;