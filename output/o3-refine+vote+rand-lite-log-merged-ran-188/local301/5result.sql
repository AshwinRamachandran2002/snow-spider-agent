WITH weekly AS (
    SELECT
        "calendar_year"          AS yr,
        DATE("week_date")        AS wk_date,
        "sales"
    FROM   "cleaned_weekly_sales"
    WHERE  "calendar_year" IN (2018, 2019, 2020)
),
agg AS (
    SELECT
        yr,
        SUM( CASE
                 /* 4 weeks (28 days) BEFORE June‑15 */
                 WHEN wk_date >= DATE(yr || '-06-15', '-28 days')
                  AND wk_date <  DATE(yr || '-06-15')
                 THEN sales
             END ) AS pre_sales,
        SUM( CASE
                 /* 4 weeks (28 days) AFTER June‑15 */
                 WHEN wk_date >  DATE(yr || '-06-15')
                  AND wk_date <= DATE(yr || '-06-15', '+28 days')
                 THEN sales
             END ) AS post_sales
    FROM weekly
    GROUP BY yr
)
SELECT
    yr                       AS calendar_year,
    pre_sales,
    post_sales,
    ROUND( (post_sales - pre_sales) * 100.0 / pre_sales , 4) AS pct_change
FROM   agg
ORDER  BY yr;