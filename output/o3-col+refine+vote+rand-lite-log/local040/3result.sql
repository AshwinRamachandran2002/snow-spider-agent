SELECT
    t."boroname",
    COUNT(*)                                   AS tree_count,
    AVG(i."Estimate_Mean_income")              AS avg_mean_income
FROM "trees" AS t
JOIN "income_trees" AS i
  ON t."zipcode" = i."zipcode"
WHERE
      i."Estimate_Median_income" > 0
  AND i."Estimate_Mean_income"  > 0
  AND t."boroname" IS NOT NULL
GROUP BY t."boroname"
ORDER BY tree_count DESC
LIMIT 3;