WITH sales_windows AS (
    /* Aggregate the 4-week “pre” and “post” periods around 15 June
       for each of the three calendar years                          */
    SELECT '2018' AS calendar_year,
           SUM(CASE
                   WHEN week_date BETWEEN '2018-05-21' AND '2018-06-17'
                   THEN sales END)        AS pre_sales,
           SUM(CASE
                   WHEN week_date BETWEEN '2018-06-18' AND '2018-07-15'
                   THEN sales END)        AS post_sales
    FROM   cleaned_weekly_sales

    UNION ALL
    SELECT '2019',
           SUM(CASE
                   WHEN week_date BETWEEN '2019-05-20' AND '2019-06-16'
                   THEN sales END),
           SUM(CASE
                   WHEN week_date BETWEEN '2019-06-17' AND '2019-07-14'
                   THEN sales END)
    FROM   cleaned_weekly_sales

    UNION ALL
    SELECT '2020',
           SUM(CASE
                   WHEN week_date BETWEEN '2020-05-18' AND '2020-06-14'
                   THEN sales END),
           SUM(CASE
                   WHEN week_date BETWEEN '2020-06-15' AND '2020-07-12'
                   THEN sales END)
    FROM   cleaned_weekly_sales
)

SELECT calendar_year,
       pre_sales,
       post_sales,
       ROUND( (post_sales - pre_sales) * 100.0 / pre_sales , 4) AS pct_change
FROM   sales_windows
ORDER  BY calendar_year;