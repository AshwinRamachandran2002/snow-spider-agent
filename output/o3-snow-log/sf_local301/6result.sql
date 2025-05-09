WITH base AS (  -- convert text date to real date and keep raw sales rows
    SELECT 
        TO_DATE("week_date", 'DD/MM/YY')          AS week_dt,
        "sales"                                   AS week_sales
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."WEEKLY_SALES"
    WHERE TRY_TO_DATE("week_date", 'DD/MM/YY') IS NOT NULL
      AND DATE_PART(year, TO_DATE("week_date", 'DD/MM/YY')) IN (2018, 2019, 2020)
), weekly_totals AS (   -- aggregate to one row per week (summing across regions, platforms, etc.)
    SELECT
        week_dt,
        DATE_PART(year, week_dt)                  AS cal_year,
        SUM(week_sales)                           AS week_sales
    FROM base
    GROUP BY week_dt
), ranked_pre AS (      -- four weeks BEFORE 15-June (exclusive), latest first
    SELECT
        cal_year,
        week_sales,
        ROW_NUMBER() OVER (
            PARTITION BY cal_year
            ORDER BY week_dt DESC
        )                                             AS rnk
    FROM weekly_totals
    WHERE week_dt < DATE_FROM_PARTS(cal_year, 6, 15)
), ranked_post AS (     -- four weeks AFTER 15-June (exclusive), earliest first
    SELECT
        cal_year,
        week_sales,
        ROW_NUMBER() OVER (
            PARTITION BY cal_year
            ORDER BY week_dt ASC
        )                                             AS rnk
    FROM weekly_totals
    WHERE week_dt > DATE_FROM_PARTS(cal_year, 6, 15)
), limited AS (        -- keep only the first 4 weeks in each side
    SELECT cal_year, 'PRE'  AS period, week_sales FROM ranked_pre  WHERE rnk <= 4
    UNION ALL
    SELECT cal_year, 'POST' AS period, week_sales FROM ranked_post WHERE rnk <= 4
), summary AS (        -- total sales for the 4-week windows
    SELECT
        cal_year,
        SUM(CASE WHEN period = 'PRE'  THEN week_sales END) AS pre_sales,
        SUM(CASE WHEN period = 'POST' THEN week_sales END) AS post_sales
    FROM limited
    GROUP BY cal_year
)
SELECT
    cal_year                                          AS "calendar_year",
    pre_sales                                         AS "sales_four_weeks_before",
    post_sales                                        AS "sales_four_weeks_after",
    ROUND( (post_sales - pre_sales) / pre_sales * 100 , 2) AS "pct_change"
FROM summary
ORDER BY cal_year;