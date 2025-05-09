SELECT
    t."boroname"                               AS borough,
    COUNT(*)                                   AS tree_count,
    AVG(i."Estimate_Mean_income")              AS avg_mean_income
FROM   "trees"         AS t
JOIN   "income_trees"  AS i
       ON t."zipcode" = i."zipcode"            -- unify trees with income by ZIP
WHERE  i."Estimate_Median_income"  > 0         -- keep only positive median income
  AND  i."Estimate_Mean_income"    > 0         -- keep only positive mean income
  AND  t."boroname"               IS NOT NULL  -- valid borough name
  AND  TRIM(t."boroname") <> ''
GROUP BY
       t."boroname"
ORDER BY
       tree_count DESC,                       -- most trees first
       borough
LIMIT 3;                                      -- top three boroughs