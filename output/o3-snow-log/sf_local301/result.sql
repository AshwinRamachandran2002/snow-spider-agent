WITH weekly_sales AS (
    SELECT
        TO_DATE("week_date_formatted")          AS week_dt ,        -- convert to DATE
        "sales"                                 AS sales   ,
        "calendar_year"                         AS yr
    FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
    WHERE "calendar_year" IN (2018, 2019, 2020)
), period_sales AS (
    SELECT
        yr                                                       AS year ,
        SUM( CASE
                 WHEN week_dt >= DATEADD(day,-28,DATE_FROM_PARTS(yr,6,15))
                      AND week_dt  < DATE_FROM_PARTS(yr,6,15)
                 THEN sales
            END )                                                AS pre_sales ,
        SUM( CASE
                 WHEN week_dt >= DATE_FROM_PARTS(yr,6,15)
                      AND week_dt  < DATEADD(day,28,DATE_FROM_PARTS(yr,6,15))
                 THEN sales
            END )                                                AS post_sales
    FROM weekly_sales
    GROUP BY yr
)
SELECT
    year ,
    pre_sales ,
    post_sales ,
    ROUND( (post_sales - pre_sales) / NULLIF(pre_sales,0) * 100 , 4) AS pct_change
FROM period_sales
ORDER BY year NULLS LAST;