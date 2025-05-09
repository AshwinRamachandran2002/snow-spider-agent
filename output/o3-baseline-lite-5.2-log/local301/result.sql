WITH params(year, jun15) AS (
    VALUES
        (2018, '2018-06-15'),
        (2019, '2019-06-15'),
        (2020, '2020-06-15')
),
period_sales AS (
    /* 4 weeks (28 days) before and 4 weeks (28 days) after June‑15 */
    SELECT
        p.year,
        CASE 
            WHEN c."week_date" < date(p.jun15) THEN 'before'
            ELSE 'after'
        END                         AS period,
        SUM(c."sales")              AS total_sales
    FROM "cleaned_weekly_sales" c
    JOIN params p
      ON c."week_date" BETWEEN date(p.jun15,'-28 days')
                           AND date(p.jun15,'+27 days')
    GROUP BY p.year, period
),
pivot AS (
    SELECT
        year,
        MAX(CASE WHEN period='before' THEN total_sales END) AS sales_before,
        MAX(CASE WHEN period='after'  THEN total_sales END) AS sales_after
    FROM period_sales
    GROUP BY year
)
SELECT
    year,
    sales_before,
    sales_after,
    ROUND( (sales_after - sales_before) * 100.0 / sales_before , 4) AS pct_change
FROM pivot
ORDER BY year;