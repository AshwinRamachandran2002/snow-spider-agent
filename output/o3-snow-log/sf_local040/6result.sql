WITH joined AS (   /* combine trees with income data by ZIP */
    SELECT 
        t."boroname",
        t."tree_id",
        i."Estimate_Mean_income"
    FROM MODERN_DATA.MODERN_DATA."TREES" t
    INNER JOIN MODERN_DATA.MODERN_DATA."INCOME_TREES" i
        ON t."zipcode" = i."zipcode"
    WHERE NVL(i."Estimate_Median_income",0) > 0
      AND NVL(i."Estimate_Mean_income",0) > 0
      AND t."boroname" IS NOT NULL
),
borough_stats AS (   /* count trees & compute average mean income per borough */
    SELECT 
        "boroname",
        COUNT("tree_id")            AS tree_count,
        AVG("Estimate_Mean_income") AS avg_mean_income
    FROM joined
    GROUP BY "boroname"
)
SELECT 
    "boroname",
    ROUND(avg_mean_income, 4) AS average_mean_income
FROM borough_stats
ORDER BY tree_count DESC NULLS LAST
LIMIT 3;