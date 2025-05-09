/* 1.  Join every tree to the income information for its ZIP code
   2.  Keep only rows whose borough name is present and whose median
       and mean income are both greater than 0
   3.  Aggregate by borough (boroname) to count trees and average the
       mean income
   4.  Return the three boroughs with the highest tree counts          */
WITH combined AS (
    SELECT
        t."boroname",
        it."Estimate_Mean_income",
        it."Estimate_Median_income"
    FROM MODERN_DATA.MODERN_DATA."TREES"           t
    LEFT JOIN MODERN_DATA.MODERN_DATA."INCOME_TREES" it
           ON t."zipcode" = it."zipcode"
),
filtered AS (
    SELECT
        "boroname",
        "Estimate_Mean_income"
    FROM combined
    WHERE "boroname" IS NOT NULL
      AND TRIM("boroname") <> ''
      AND "Estimate_Median_income" > 0
      AND "Estimate_Mean_income"  > 0
),
borough_stats AS (
    SELECT
        "boroname",
        COUNT(*)                              AS tree_count,
        AVG("Estimate_Mean_income")           AS avg_mean_income
    FROM filtered
    GROUP BY "boroname"
)
SELECT
    "boroname",
    tree_count,
    ROUND(avg_mean_income, 4) AS avg_mean_income
FROM borough_stats
ORDER BY tree_count DESC NULLS LAST
LIMIT 3;