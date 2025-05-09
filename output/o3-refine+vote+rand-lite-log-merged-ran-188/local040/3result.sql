SELECT
    t."boroname"                                   AS borough,
    COUNT(*)                                       AS tree_count,
    AVG(it."Estimate_Mean_income")                 AS avg_mean_income
FROM "trees"            AS t
LEFT JOIN "income_trees" AS it
       ON t."zipcode" = it."zipcode"               -- unify by ZIP code
WHERE
      t."boroname" IS NOT NULL                     -- ensure valid borough name
  AND it."Estimate_Median_income" > 0              -- keep rows with valid income data
  AND it."Estimate_Mean_income"   > 0
GROUP BY
    t."boroname"
ORDER BY
    tree_count DESC,                               -- highest number of trees first
    borough
LIMIT 3;