/* Top three boroughs by tree count together with their average mean income */
SELECT
    t.boroname                          AS borough,
    COUNT(*)                            AS num_trees,
    AVG(it.Estimate_Mean_income)        AS avg_mean_income
FROM   trees AS t
JOIN   income_trees AS it
       ON t.zipcode = it.zipcode               -- unify trees with income by ZIP
WHERE  it.Estimate_Median_income  > 0          -- keep only valid income rows
  AND  it.Estimate_Mean_income    > 0
  AND  t.boroname                 IS NOT NULL  -- ensure borough name exists
GROUP  BY t.boroname
ORDER  BY num_trees DESC, borough              -- highest tree counts first
LIMIT  3;