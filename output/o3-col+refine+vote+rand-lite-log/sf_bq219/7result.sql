WITH last_full_month AS (              -- identify the latest fully-completed month in the data
    SELECT CASE
             WHEN DATE_TRUNC('month', CURRENT_DATE) = DATE_TRUNC('month', MAX("date"))
                  THEN DATEADD(month, -1, DATE_TRUNC('month', MAX("date")))
             ELSE DATE_TRUNC('month', MAX("date"))
           END AS "last_month"
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
    WHERE "date" >= '2022-01-01'
),

sales_in_scope AS (                    -- limit rows to 2022-01-01 through that month’s end
    SELECT s.*
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES s
    CROSS JOIN last_full_month l
    WHERE s."date" >= '2022-01-01'
      AND s."date" <  DATEADD(month, 1, l."last_month")   -- strictly before 1st day of next month
),

monthly_totals AS (                    -- total liters per month
    SELECT DATE_TRUNC('month', "date") AS "month",
           SUM("volume_sold_liters")   AS "total_liters"
    FROM sales_in_scope
    GROUP BY 1
),

month_pct AS (                         -- category’s % share per month
    SELECT DATE_TRUNC('month', s."date")                       AS "month",
           s."category_name",
           SUM(s."volume_sold_liters") / t."total_liters" * 100  AS "pct_of_total"
    FROM sales_in_scope s
    JOIN monthly_totals t
      ON DATE_TRUNC('month', s."date") = t."month"
    GROUP BY 1, 2, t."total_liters"
),

qualified AS (                         -- categories meeting 24-month & ≥1 % criteria
    SELECT "category_name"
    FROM month_pct
    GROUP BY 1
    HAVING COUNT(DISTINCT "month") >= 24
       AND AVG("pct_of_total")    >= 1
),

pairs AS (                             -- all pairwise Pearson correlations
    SELECT a."category_name"                        AS "cat1",
           b."category_name"                        AS "cat2",
           CORR(a."pct_of_total", b."pct_of_total") AS "pearson_corr"
    FROM month_pct a
    JOIN month_pct b
      ON a."month" = b."month"
     AND a."category_name" < b."category_name"
    WHERE a."category_name" IN (SELECT "category_name" FROM qualified)
      AND b."category_name" IN (SELECT "category_name" FROM qualified)
    GROUP BY 1, 2
)

SELECT "cat1" AS "category_with_lowest_corr",
       "cat2" AS "paired_category",
       "pearson_corr"
FROM pairs
ORDER BY "pearson_corr" ASC
LIMIT 1;