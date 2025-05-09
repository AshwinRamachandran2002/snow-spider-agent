SELECT
    t.boroname AS borough,
    COUNT(*)   AS number_of_trees,
    ROUND(AVG(i.Estimate_Mean_income), 2) AS average_mean_income
FROM trees AS t
JOIN income_trees AS i
  ON t.zipcode = i.zipcode
WHERE i.Estimate_Median_income > 0
  AND i.Estimate_Mean_income  > 0
  AND t.boroname IS NOT NULL
GROUP BY t.boroname
ORDER BY number_of_trees DESC
LIMIT 3;