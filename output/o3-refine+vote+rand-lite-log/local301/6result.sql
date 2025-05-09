WITH data AS (
    /* collect the cleaned weekly data for the required years */
    SELECT
        CAST(SUBSTR("week_date", 1, 4) AS INTEGER) AS sales_year,
        DATE("week_date")                    AS week_start,
        "sales"
    FROM   "cleaned_weekly_sales"
    WHERE  CAST(SUBSTR("week_date", 1, 4) AS INTEGER) IN (2018, 2019, 2020)
),
period_totals AS (
    /* sum sales in the four weeks before and after 15‑June for each year */
    SELECT
        sales_year                                   AS calendar_year,
        SUM(
            CASE
                WHEN week_start <= DATE(sales_year || '-06-15')
                     AND week_start >  DATE(sales_year || '-06-15','-28 days')
                THEN sales
            END
        )                                            AS sales_before,
        SUM(
            CASE
                WHEN week_start >  DATE(sales_year || '-06-15')
                     AND week_start <= DATE(sales_year || '-06-15','+28 days')
                THEN sales
            END
        )                                            AS sales_after
    FROM data
    GROUP BY sales_year
)
SELECT
    calendar_year,
    sales_before,
    sales_after,
    ROUND((sales_after - sales_before) * 100.0 / sales_before, 4) AS pct_change
FROM period_totals
ORDER BY calendar_year;