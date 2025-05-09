WITH anchor AS (
    /* locate the week that contains 15 June for each year */
    SELECT
        calendar_year,
        MIN(week_number) AS anchor_week
    FROM cleaned_weekly_sales
    WHERE calendar_year IN (2018, 2019, 2020)
      AND substr(week_date, 6, 2) = '06'                      -- June
      AND CAST(substr(week_date, 9, 2) AS INTEGER) BETWEEN 10 AND 19
    GROUP BY calendar_year
),
sales_periods AS (
    /* sum sales for the four weeks before and after the anchor week */
    SELECT
        c.calendar_year,
        SUM(CASE
                WHEN c.week_number BETWEEN a.anchor_week - 4 AND a.anchor_week - 1
                THEN c.sales END) AS pre_period_sales,
        SUM(CASE
                WHEN c.week_number BETWEEN a.anchor_week + 1 AND a.anchor_week + 4
                THEN c.sales END) AS post_period_sales
    FROM cleaned_weekly_sales AS c
    JOIN anchor AS a
      ON c.calendar_year = a.calendar_year
    WHERE c.week_number BETWEEN a.anchor_week - 4 AND a.anchor_week + 4
    GROUP BY c.calendar_year
)
SELECT
    calendar_year AS year,
    pre_period_sales,
    post_period_sales,
    ROUND(
        (post_period_sales - pre_period_sales) * 100.0 / pre_period_sales,
        4
    ) AS percent_change
FROM sales_periods
ORDER BY calendar_year;