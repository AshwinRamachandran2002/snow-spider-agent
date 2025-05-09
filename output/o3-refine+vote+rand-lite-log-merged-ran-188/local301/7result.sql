WITH mid_june_windows AS (
    /* take all records for the 3 required calendar years */
    SELECT
        "calendar_year"      AS sales_year,
        DATE("week_date")    AS week_start,
        "sales"
    FROM   "cleaned_weekly_sales"
    WHERE  "calendar_year" IN (2018, 2019, 2020)
),
flag_periods AS (
    /* flag the 4‑week window before (pre) and after (post) 15‑June of each year */
    SELECT
        sales_year,
        sales,
        CASE
            WHEN week_start BETWEEN DATE(sales_year || '-06-15', '-28 days')
                               AND DATE(sales_year || '-06-15', '-1 day')   THEN 'pre'
            WHEN week_start BETWEEN DATE(sales_year || '-06-15')
                               AND DATE(sales_year || '-06-15', '+27 days') THEN 'post'
        END AS period
    FROM   mid_june_windows
)
SELECT
    sales_year                                     AS year,
    SUM(CASE WHEN period = 'pre'  THEN sales END)  AS pre4_week_sales,
    SUM(CASE WHEN period = 'post' THEN sales END)  AS post4_week_sales,
    ROUND(
        (SUM(CASE WHEN period = 'post' THEN sales END) -
         SUM(CASE WHEN period = 'pre'  THEN sales END)) * 100.0 /
         SUM(CASE WHEN period = 'pre'  THEN sales END), 2
    )                                              AS pct_change
FROM   flag_periods
WHERE  period IS NOT NULL
GROUP  BY sales_year
ORDER  BY sales_year;