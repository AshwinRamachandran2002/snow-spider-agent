-- Top-3 boroughs by tree count (only rows with valid borough name and
-- positive median & mean income), along with their average mean income
SELECT
    t."boroname"                                   AS borough,
    ROUND(AVG(i."Estimate_Mean_income"), 4)        AS avg_mean_income
FROM   "trees"        AS t
JOIN   "income_trees" AS i
       ON t."zipcode" = i."zipcode"
WHERE  t."boroname" IS NOT NULL
  AND  i."Estimate_Median_income" > 0
  AND  i."Estimate_Mean_income"   > 0
GROUP BY t."boroname"
ORDER BY COUNT(*) DESC
LIMIT 3;