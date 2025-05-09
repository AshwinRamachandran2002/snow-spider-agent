WITH sales_periods AS (
    SELECT
        calendar_year                                   AS year,
        CASE
            WHEN date(week_date) <  date(calendar_year || '-06-15')
             AND date(week_date) >= date(calendar_year || '-06-15', '-28 day')
                 THEN 'before'        -- four weeks leading up to 15 Jun
            WHEN date(week_date) >= date(calendar_year || '-06-15')
             AND date(week_date) <= date(calendar_year || '-06-15', '+27 day')
                 THEN 'after'         -- four weeks following 15 Jun
        END                                             AS period,
        SUM(sales)                                      AS period_sales
    FROM   cleaned_weekly_sales
    WHERE  calendar_year IN (2018, 2019, 2020)
      AND  (
              (date(week_date) <  date(calendar_year || '-06-15')
               AND date(week_date) >= date(calendar_year || '-06-15', '-28 day'))
           OR (date(week_date) >= date(calendar_year || '-06-15')
               AND date(week_date) <= date(calendar_year || '-06-15', '+27 day'))
           )
    GROUP  BY calendar_year,
              period
),
pivot AS (
    SELECT
        year,
        SUM(CASE WHEN period = 'before' THEN period_sales END) AS before_sales,
        SUM(CASE WHEN period = 'after'  THEN period_sales END) AS after_sales
    FROM   sales_periods
    GROUP  BY year
)
SELECT
    year,
    before_sales,
    after_sales,
    ROUND((after_sales - before_sales) * 100.0 / before_sales, 4) AS pct_change
FROM   pivot
ORDER BY year;