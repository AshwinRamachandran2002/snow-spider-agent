WITH parsed AS (
    SELECT 
        TO_DATE("week_date", 'DD/MM/YY')            AS week_dt,
        "sales"
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."WEEKLY_SALES"
),
period_tagged AS (
    SELECT
        YEAR(week_dt)                                                   AS yr,
        "sales",
        CASE
            /* four weeks (28 days) leading up to 15-Jun */
            WHEN week_dt <= DATE_FROM_PARTS(YEAR(week_dt), 6, 15)
                 AND week_dt >  DATEADD(day, -28, DATE_FROM_PARTS(YEAR(week_dt), 6, 15))
                 THEN 'pre'
            /* four weeks (28 days) following 15-Jun */
            WHEN week_dt >  DATE_FROM_PARTS(YEAR(week_dt), 6, 15)
                 AND week_dt <= DATEADD(day,  28, DATE_FROM_PARTS(YEAR(week_dt), 6, 15))
                 THEN 'post'
        END                                                            AS period
    FROM parsed
    WHERE YEAR(week_dt) IN (2018, 2019, 2020)
),
aggregated AS (
    SELECT
        yr,
        period,
        SUM("sales") AS total_sales
    FROM period_tagged
    WHERE period IS NOT NULL
    GROUP BY yr, period
),
pivoted AS (
    SELECT
        yr,
        MAX(CASE WHEN period = 'pre'  THEN total_sales END) AS pre_sales,
        MAX(CASE WHEN period = 'post' THEN total_sales END) AS post_sales
    FROM aggregated
    GROUP BY yr
)
SELECT
    yr                                            AS "year",
    pre_sales                                     AS "sales_before_june15",
    post_sales                                    AS "sales_after_june15",
    ROUND((post_sales - pre_sales) / pre_sales * 100, 4) 
                                                  AS "pct_change_after_vs_before"
FROM pivoted
ORDER BY yr;