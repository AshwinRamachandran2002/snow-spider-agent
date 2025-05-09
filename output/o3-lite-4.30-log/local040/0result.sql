WITH borough_stats AS (
    SELECT
        t.boroname                  AS borough,
        COUNT(*)                    AS num_trees,
        AVG(i.Estimate_Mean_income) AS average_mean_income
    FROM trees AS t
    JOIN income_trees AS i
      ON t.zipcode = i.zipcode
    WHERE i.Estimate_Median_income > 0
      AND i.Estimate_Mean_income  > 0
      AND t.boroname IS NOT NULL
      AND t.boroname <> ''
    GROUP BY t.boroname
)
SELECT
    borough,
    printf('%.4f', average_mean_income) AS average_mean_income
FROM borough_stats
ORDER BY num_trees DESC
LIMIT 3;