SELECT
    yr AS year,
    pre_sales AS pre_period_sales,
    post_sales AS post_period_sales,
    ROUND(100.0 * (post_sales - pre_sales) / pre_sales, 4) AS percent_change
FROM (
    SELECT
        "calendar_year" AS yr,
        SUM(
            CASE
                WHEN "week_date" BETWEEN DATE("calendar_year" || '-06-15','-28 day')
                                    AND     DATE("calendar_year" || '-06-15','-1 day')
                THEN "sales"
            END
        ) AS pre_sales,
        SUM(
            CASE
                WHEN "week_date" BETWEEN DATE("calendar_year" || '-06-15')
                                    AND     DATE("calendar_year" || '-06-15','+27 day')
                THEN "sales"
            END
        ) AS post_sales
    FROM "cleaned_weekly_sales"
    WHERE "calendar_year" IN (2018, 2019, 2020)
    GROUP BY "calendar_year"
) AS t
ORDER BY year;