WITH sales_before AS (
    SELECT calendar_year,
           SUM(sales) AS sales_before
    FROM cleaned_weekly_sales
    WHERE (week_date BETWEEN '2018-05-18' AND '2018-06-14')
       OR (week_date BETWEEN '2019-05-18' AND '2019-06-14')
       OR (week_date BETWEEN '2020-05-18' AND '2020-06-14')
    GROUP BY calendar_year
),
sales_after AS (
    SELECT calendar_year,
           SUM(sales) AS sales_after
    FROM cleaned_weekly_sales
    WHERE (week_date BETWEEN '2018-06-15' AND '2018-07-13')
       OR (week_date BETWEEN '2019-06-15' AND '2019-07-13')
       OR (week_date BETWEEN '2020-06-15' AND '2020-07-13')
    GROUP BY calendar_year
)
SELECT 
    a.calendar_year,
    b.sales_before,
    a.sales_after,
    ROUND((a.sales_after - b.sales_before) * 100.0 / b.sales_before, 4) AS pct_change_after_vs_before
FROM sales_after a
JOIN sales_before b USING (calendar_year)
ORDER BY a.calendar_year;