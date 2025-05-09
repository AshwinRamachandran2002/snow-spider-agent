WITH years AS (
    SELECT 2018 AS year
    UNION ALL SELECT 2019
    UNION ALL SELECT 2020
),
agg AS (
    SELECT  y.year,
            SUM(
                CASE
                    WHEN date(cws."week_date") BETWEEN date(y.year || '-06-15','-28 day')
                                                  AND date(y.year || '-06-15','-1 day')
                    THEN cws."sales"
                END
            ) AS pre_period_sales,
            SUM(
                CASE
                    WHEN date(cws."week_date") BETWEEN date(y.year || '-06-15','+1 day')
                                                  AND date(y.year || '-06-15','+28 day')
                    THEN cws."sales"
                END
            ) AS post_period_sales
    FROM    years y
    LEFT JOIN "cleaned_weekly_sales" cws
           ON cws."calendar_year" = y.year
    GROUP BY y.year
)
SELECT  year,
        pre_period_sales,
        post_period_sales,
        ROUND(100.0 * (post_period_sales - pre_period_sales) / pre_period_sales, 4) 
          AS percent_change
FROM    agg
ORDER BY year;