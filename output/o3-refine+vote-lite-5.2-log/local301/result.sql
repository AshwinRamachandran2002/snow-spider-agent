WITH weekly AS (
    /* keep only the columns we need and make sure the date is in ISO format */
    SELECT
        week_date,            -- already YYYY-MM-DD in cleaned_weekly_sales
        calendar_year,
        sales
    FROM cleaned_weekly_sales
    WHERE calendar_year IN (2018, 2019, 2020)
),
tagged AS (
    /* label each week as one of the two 4‑week windows relative to 15 June */
    SELECT
        calendar_year,
        sales,
        CASE
            WHEN date(week_date) BETWEEN date(calendar_year || '-06-15', '-28 day')
                                   AND     date(calendar_year || '-06-14')
                 THEN 'before'
            WHEN date(week_date) BETWEEN date(calendar_year || '-06-15')
                                   AND     date(calendar_year || '-06-15', '+27 day')
                 THEN 'after'
        END AS period
    FROM weekly
),
summed AS (
    /* total sales for each period in each year */
    SELECT
        calendar_year,
        period,
        SUM(sales) AS period_sales
    FROM tagged
    WHERE period IS NOT NULL
    GROUP BY calendar_year, period
),
pivot AS (
    /* put the two period totals side‑by‑side */
    SELECT
        calendar_year,
        SUM(CASE WHEN period = 'before' THEN period_sales END) AS before_sales,
        SUM(CASE WHEN period = 'after'  THEN period_sales END) AS after_sales
    FROM summed
    GROUP BY calendar_year
)
SELECT
    calendar_year      AS year,
    before_sales,
    after_sales,
    ROUND((after_sales - before_sales) * 100.0 / before_sales, 4) AS pct_change
FROM pivot
ORDER BY year;