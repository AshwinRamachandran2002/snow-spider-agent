WITH combined AS (
    SELECT 
        t."boroname"                           AS borough,
        i."Estimate_Mean_income"               AS mean_income,
        i."Estimate_Median_income"             AS median_income
    FROM MODERN_DATA.MODERN_DATA."TREES"        t
    LEFT JOIN MODERN_DATA.MODERN_DATA."INCOME_TREES" i
           ON t."zipcode" = i."zipcode"
), 
filtered AS (
    SELECT *
    FROM combined
    WHERE borough IS NOT NULL
      AND TRIM(borough) <> ''
      AND mean_income  > 0
      AND median_income > 0
)
SELECT 
    borough,
    COUNT(*)                                  AS tree_count,
    ROUND(AVG(mean_income), 2)                AS avg_mean_income
FROM filtered
GROUP BY borough
ORDER BY tree_count DESC NULLS LAST
LIMIT 3;