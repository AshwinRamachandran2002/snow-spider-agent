/*  Top-3 boroughs with the largest tree counts together with
    their average mean household income (only rows whose
    mean & median income are both > 0 and with a valid borough name) */
SELECT
        t."boroname"                        AS "borough",
        COUNT(*)                            AS "tree_count",
        AVG(i."Estimate_Mean_income")       AS "avg_mean_income"
FROM    MODERN_DATA.MODERN_DATA."TREES"         t
LEFT JOIN MODERN_DATA.MODERN_DATA."INCOME_TREES" i
       ON t."zipcode" = i."zipcode"
WHERE   t."boroname" IS NOT NULL
  AND   TRIM(t."boroname") <> ''
  AND   i."Estimate_Median_income" > 0
  AND   i."Estimate_Mean_income"  > 0
GROUP BY
        t."boroname"
ORDER BY
        "tree_count" DESC NULLS LAST
LIMIT 3;