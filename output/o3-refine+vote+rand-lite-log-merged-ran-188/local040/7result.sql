SELECT
    t."boroname"                              AS borough,
    COUNT(*)                                  AS tree_count,
    ROUND(AVG(it."Estimate_Mean_income"), 4)  AS avg_mean_income
FROM
    "trees"         AS t
JOIN
    "income_trees"  AS it
      ON t."zipcode" = it."zipcode"
WHERE
    it."Estimate_Median_income" > 0
    AND it."Estimate_Mean_income"  > 0
    AND t."boroname" IS NOT NULL
GROUP BY
    t."boroname"
ORDER BY
    tree_count DESC,
    borough
LIMIT 3;