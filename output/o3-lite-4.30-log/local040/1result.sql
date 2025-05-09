SELECT borough,
       average_mean_income
FROM (
    SELECT t.boroname AS borough,
           COUNT(*) AS total_trees,
           ROUND(AVG(i.Estimate_Mean_income), 4) AS average_mean_income
    FROM trees AS t
    JOIN income_trees AS i
      ON t.zipcode = i.zipcode
    WHERE i.Estimate_Median_income > 0
      AND i.Estimate_Mean_income  > 0
      AND t.boroname IS NOT NULL
      AND t.boroname <> ''
    GROUP BY t.boroname
) AS ranked
ORDER BY total_trees DESC
LIMIT 3;