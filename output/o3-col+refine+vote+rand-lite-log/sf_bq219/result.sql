WITH cutoff AS (   -- first day of the current month (partial data not yet complete)
    SELECT DATE_TRUNC('month', CURRENT_DATE) AS first_day_curr_month
),

filtered AS (      -- restrict to 2022-01-01 through the last FULLY completed month
    SELECT 
        s."date",
        s."category_name",
        s."volume_sold_liters"
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES."SALES" s
    JOIN cutoff c
      ON s."date" <  c.first_day_curr_month        -- exclude current partial month
     AND s."date" >= '2022-01-01'                  -- analysis window start
),

/* total liters sold each month (all categories) */
month_totals AS (
    SELECT 
        DATE_TRUNC('month', "date")        AS "month",
        SUM("volume_sold_liters")          AS "tot_liters"
    FROM filtered
    GROUP BY DATE_TRUNC('month', "date")
),

/* liters sold per category per month */
cat_month AS (
    SELECT 
        DATE_TRUNC('month', "date")        AS "month",
        "category_name",
        SUM("volume_sold_liters")          AS "cat_liters"
    FROM filtered
    GROUP BY DATE_TRUNC('month', "date"), "category_name"
),

/* monthly share (percentage of total liters) for every category */
shares AS (
    SELECT 
        c."month",
        c."category_name",
        c."cat_liters" / m."tot_liters"    AS "share_pct"
    FROM cat_month c
    JOIN month_totals m
      ON c."month" = m."month"
),

/* keep only categories that (a) appear in ≥24 months and (b) average ≥1 % share */
qualifying AS (
    SELECT 
        "category_name"
    FROM shares
    GROUP BY "category_name"
    HAVING COUNT(*) >= 24
       AND AVG("share_pct") >= 0.01
),

qshares AS (   -- shares for qualifying categories only
    SELECT s.*
    FROM shares s
    JOIN qualifying q
      ON s."category_name" = q."category_name"
),

/* compute pair-wise Pearson correlations of monthly shares */
corr_tbl AS (
    SELECT 
        a."category_name"                                  AS "cat_a",
        b."category_name"                                  AS "cat_b",
        CORR(a."share_pct", b."share_pct")                 AS "pearson_r"
    FROM qshares a
    JOIN qshares b
      ON a."month" = b."month"
     AND a."category_name" < b."category_name"             -- avoid duplicates/self-pairs
    GROUP BY a."category_name", b."category_name"
)

/* final answer: the two least-correlated qualifying categories */
SELECT 
    "cat_a"       AS "category_1",
    "cat_b"       AS "category_2",
    "pearson_r"   AS "lowest_pearson_r"
FROM corr_tbl
ORDER BY "pearson_r" ASC
LIMIT 1;