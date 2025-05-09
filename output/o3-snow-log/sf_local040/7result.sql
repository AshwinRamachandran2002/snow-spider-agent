WITH combined AS (
    SELECT
        t."tree_id",
        t."boroname",
        COALESCE(t."zipcode", i."zipcode")      AS "zipcode",
        i."Estimate_Mean_income",
        i."Estimate_Median_income"
    FROM MODERN_DATA.MODERN_DATA."TREES"        t
    LEFT JOIN MODERN_DATA.MODERN_DATA."INCOME_TREES" i
           ON t."zipcode" = i."zipcode"
)
SELECT
    c."boroname"                            AS "borough",
    COUNT(*)                                AS "tree_count",
    AVG(c."Estimate_Mean_income")           AS "average_mean_income"
FROM combined c
WHERE c."Estimate_Mean_income"  > 0
  AND c."Estimate_Median_income" > 0
  AND c."boroname" IS NOT NULL
GROUP BY c."boroname"
ORDER BY "tree_count" DESC NULLS LAST
LIMIT 3;