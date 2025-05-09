WITH month_bounds AS (
    /*  first month to include and the last fully-completed month */
    SELECT 
        TO_DATE('2022-01-01')                           AS "start_dt",
        DATEADD(month, -1, DATE_TRUNC('month', CURRENT_DATE())) AS "end_dt"
),
month_tot AS (   -- total liters each calendar month
    SELECT
        DATE_TRUNC('month', s."date")      AS "month",
        SUM(s."volume_sold_liters")        AS "total_liters"
    FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES" s
    JOIN month_bounds mb
      ON s."date" >= mb."start_dt"
     AND s."date" <= mb."end_dt"
    GROUP BY 1
),
month_cat AS (   -- liters per category per month
    SELECT
        DATE_TRUNC('month', s."date")      AS "month",
        s."category_name",
        SUM(s."volume_sold_liters")        AS "cat_liters"
    FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES" s
    JOIN month_bounds mb
      ON s."date" >= mb."start_dt"
     AND s."date" <= mb."end_dt"
    GROUP BY 1, 2
),
cat_stats AS (   -- keep categories that meet the 1 % / 24-month rule
    SELECT
        mc."category_name",
        COUNT(*)                                            AS "months_with_sales",
        AVG(mc."cat_liters" / NULLIF(mt."total_liters",0))  AS "avg_share"
    FROM month_cat mc
    JOIN month_tot mt
      ON mc."month" = mt."month"
    GROUP BY 1
    HAVING AVG(mc."cat_liters" / NULLIF(mt."total_liters",0)) >= 0.01
       AND COUNT(*) >= 24
),
pct_tbl AS (      -- monthly share for qualifying categories
    SELECT
        mc."month",
        mc."category_name",
        mc."cat_liters" / NULLIF(mt."total_liters",0)  AS "pct_of_total"
    FROM month_cat mc
    JOIN month_tot mt
      ON mc."month" = mt."month"
    WHERE mc."category_name" IN (SELECT "category_name" FROM cat_stats)
)
SELECT 
    c1."category_name"  AS "category_1",
    c2."category_name"  AS "category_2",
    CORR(p1."pct_of_total", p2."pct_of_total") AS "pearson_corr"
FROM pct_tbl p1
JOIN pct_tbl p2
  ON p1."month" = p2."month"
 AND p1."category_name" < p2."category_name"           -- prevent self / duplicate pairs
JOIN cat_stats c1 ON p1."category_name" = c1."category_name"
JOIN cat_stats c2 ON p2."category_name" = c2."category_name"
GROUP BY c1."category_name", c2."category_name"
ORDER BY "pearson_corr" ASC NULLS LAST
LIMIT 1;