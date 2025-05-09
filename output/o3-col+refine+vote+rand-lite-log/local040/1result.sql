WITH joined AS (
    SELECT t."boroname",
           i."Estimate_Mean_income"
    FROM   "trees"        AS t
    JOIN   "income_trees" AS i
           ON t."zipcode" = i."zipcode"
    WHERE  t."boroname" IS NOT NULL
      AND  i."Estimate_Median_income" > 0
      AND  i."Estimate_Mean_income"   > 0
)
SELECT  "boroname",
        COUNT(*)                           AS "tree_count",
        ROUND(AVG("Estimate_Mean_income"), 4) AS "avg_mean_income"
FROM     joined
GROUP BY "boroname"
ORDER BY "tree_count" DESC
LIMIT 3;