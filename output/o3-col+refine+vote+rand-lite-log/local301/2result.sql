WITH sales_window AS (
    SELECT
        "calendar_year",
        SUM(CASE
                WHEN "week_date" BETWEEN DATE("calendar_year" || '-06-15', '-28 days')
                                   AND     DATE("calendar_year" || '-06-15', '-1 day')
                THEN "sales"
            END) AS sales_before,
        SUM(CASE
                WHEN "week_date" BETWEEN DATE("calendar_year" || '-06-15')
                                   AND     DATE("calendar_year" || '-06-15', '+27 days')
                THEN "sales"
            END) AS sales_after
    FROM "cleaned_weekly_sales"
    WHERE "calendar_year" IN (2018, 2019, 2020)
    GROUP BY "calendar_year"
)
SELECT
    "calendar_year",
    ROUND(100.0 * (sales_after - sales_before) / sales_before, 4) AS "pct_change"
FROM sales_window
ORDER BY "calendar_year";