WITH merged AS (
    SELECT
        t."boroname"                        AS borough,
        it."Estimate_Median_income"         AS median_income,
        it."Estimate_Mean_income"           AS mean_income
    FROM "trees" AS t
    LEFT JOIN "income_trees" AS it
           ON t."zipcode" = it."zipcode"
)
SELECT
    borough,
    ROUND(AVG(mean_income), 4) AS avg_mean_income
FROM merged
WHERE borough IS NOT NULL
  AND TRIM(borough) <> ''
  AND median_income > 0
  AND mean_income  > 0
GROUP BY borough
ORDER BY COUNT(*) DESC
LIMIT 3;