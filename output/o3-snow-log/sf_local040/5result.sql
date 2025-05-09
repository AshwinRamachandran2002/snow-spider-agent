WITH combined AS (
    /* unify tree records with income data on ZIP code,
       treating 0 ZIPs as missing and ignoring blank borough names */
    SELECT
        t."boroname",
        i."Estimate_Mean_income"
    FROM MODERN_DATA.MODERN_DATA."TREES"            AS t
    JOIN MODERN_DATA.MODERN_DATA."INCOME_TREES"     AS i
          /* if a tree ZIP is 0 (or NULL), fall back on income ZIP so rows
             with invalid ZIPs are excluded; otherwise join on the tree ZIP */
        ON COALESCE(NULLIF(t."zipcode",0), i."zipcode") = i."zipcode"
    WHERE
          i."Estimate_Median_income" > 0
      AND i."Estimate_Mean_income"  > 0
      AND TRIM(COALESCE(t."boroname",'')) <> ''
),
borough_stats AS (
    SELECT
        "boroname",
        COUNT(*)                       AS tree_count,
        AVG("Estimate_Mean_income")    AS avg_mean_income
    FROM combined
    GROUP BY "boroname"
)
SELECT
    "boroname"                       AS borough,
    avg_mean_income
FROM borough_stats
ORDER BY tree_count DESC NULLS LAST
LIMIT 3;