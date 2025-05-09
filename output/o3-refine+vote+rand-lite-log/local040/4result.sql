SELECT
    t.boroname AS borough,
    COUNT(*) AS tree_count,
    ROUND(AVG(i."Estimate_Mean_income"), 4) AS avg_mean_income
FROM trees t
JOIN income_trees i
  ON t.zipcode = i.zipcode
WHERE i."Estimate_Median_income" > 0
  AND i."Estimate_Mean_income" > 0
  AND t.boroname IS NOT NULL
  AND TRIM(t.boroname) <> ''
GROUP BY t.boroname
ORDER BY tree_count DESC, borough
LIMIT 3;