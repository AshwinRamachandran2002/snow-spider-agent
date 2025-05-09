WITH date_limits AS (
    SELECT 
        DATE '2022-01-01'                AS start_date ,
        DATE_TRUNC('month', CURRENT_DATE) AS this_month_start          -- first day of current month
),

/* 1.  Monthly sales dollars per category (from Jan‑2022 through last fully‑completed month) */
filtered_sales AS (
    SELECT
        DATE_TRUNC('month', "date")              AS "MONTH" ,
        "category_name"                          AS "CATEGORY_NAME" ,
        SUM("sale_dollars")                      AS "SALES_DOLLARS"
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES , date_limits
    WHERE "date" >= start_date
      AND "date" <  this_month_start             -- exclude the current (partial) month
    GROUP BY "MONTH" , "CATEGORY_NAME"
),

/* 2.  Total sales dollars for each month */
monthly_totals AS (
    SELECT 
        "MONTH" ,
        SUM("SALES_DOLLARS") AS "MONTH_TOTAL"
    FROM filtered_sales
    GROUP BY "MONTH"
),

/* 3.  Monthly share (percentage of total) for every category */
monthly_shares AS (
    SELECT
        fs."MONTH" ,
        fs."CATEGORY_NAME" ,
        fs."SALES_DOLLARS" / mt."MONTH_TOTAL"   AS "SHARE"
    FROM filtered_sales fs
    JOIN monthly_totals mt
      ON mt."MONTH" = fs."MONTH"
),

/* 4.  Keep only categories that (a) appear in ≥24 months and (b) average ≥1 % share */
candidate_categories AS (
    SELECT
        "CATEGORY_NAME" ,
        COUNT(DISTINCT "MONTH")        AS "MONTHS_WITH_DATA" ,
        AVG("SHARE")                   AS "AVG_MONTHLY_SHARE"
    FROM monthly_shares
    GROUP BY "CATEGORY_NAME"
    HAVING "MONTHS_WITH_DATA" >= 24
       AND "AVG_MONTHLY_SHARE" >= 0.01            -- ≥ 1 %
),

/* 5.  List of all months in the analysis window (needed to fill missing months with 0) */
all_months AS (
    SELECT DISTINCT "MONTH" FROM monthly_totals
),

/* 6.  Pair‑wise Pearson correlations of monthly shares (missing months treated as 0) */
pairwise_corr AS (
    SELECT
        c1."CATEGORY_NAME"                         AS "CATEGORY_1" ,
        c2."CATEGORY_NAME"                         AS "CATEGORY_2" ,
        CORR( COALESCE(s1."SHARE",0.0) ,
              COALESCE(s2."SHARE",0.0) )           AS "CORR_COEFF"
    FROM candidate_categories c1
    JOIN candidate_categories c2
          ON c1."CATEGORY_NAME" < c2."CATEGORY_NAME"      -- avoid duplicates / self‑pairs
    JOIN all_months m
          ON 1 = 1                                        -- cross‑join to every month
    LEFT JOIN monthly_shares s1
          ON s1."CATEGORY_NAME" = c1."CATEGORY_NAME"
         AND s1."MONTH"         = m."MONTH"
    LEFT JOIN monthly_shares s2
          ON s2."CATEGORY_NAME" = c2."CATEGORY_NAME"
         AND s2."MONTH"         = m."MONTH"
    GROUP BY "CATEGORY_1", "CATEGORY_2"
)

/* 7.  Return the pair having the smallest (most negative) correlation */
SELECT 
    "CATEGORY_1"  AS "CATEGORY_NAME_1",
    "CATEGORY_2"  AS "CATEGORY_NAME_2",
    "CORR_COEFF"  AS "PEARSON_CORR_COEFFICIENT"
FROM pairwise_corr
WHERE "CORR_COEFF" IS NOT NULL
ORDER BY "CORR_COEFF" ASC NULLS LAST
LIMIT 1;