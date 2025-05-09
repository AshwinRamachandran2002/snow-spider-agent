WITH COMBINED_DATA AS (
    SELECT
        T."boroname"                                        AS "borough",
        T."tree_id",
        I."Estimate_Mean_income"                           AS "mean_income",
        I."Estimate_Median_income"                         AS "median_income"
    FROM MODERN_DATA.MODERN_DATA.TREES            T
    LEFT JOIN MODERN_DATA.MODERN_DATA.INCOME_TREES I
           ON T."zipcode" = I."zipcode"
    WHERE NVL(I."Estimate_Mean_income", 0)  > 0
      AND NVL(I."Estimate_Median_income", 0) > 0
      AND T."boroname" IS NOT NULL
      AND TRIM(T."boroname") <> ''
)

SELECT
    "borough",
    COUNT(*)                                 AS "tree_count",
    AVG("mean_income")                       AS "avg_mean_income"
FROM COMBINED_DATA
GROUP BY "borough"
ORDER BY "tree_count" DESC NULLS LAST
LIMIT 3;