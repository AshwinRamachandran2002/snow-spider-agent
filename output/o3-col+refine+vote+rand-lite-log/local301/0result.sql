WITH period_sales AS (
    /* --------------------------- 2018 --------------------------- */
    SELECT 
        "calendar_year",
        CASE 
            WHEN "week_date" BETWEEN '2018-05-21' AND '2018-06-17' THEN 'before'
            WHEN "week_date" BETWEEN '2018-06-18' AND '2018-07-15' THEN 'after'
        END  AS period,
        "sales"
    FROM "cleaned_weekly_sales"
    WHERE "calendar_year" = 2018
      AND "week_date" BETWEEN '2018-05-21' AND '2018-07-15'

    UNION ALL
    /* --------------------------- 2019 --------------------------- */
    SELECT 
        "calendar_year",
        CASE 
            WHEN "week_date" BETWEEN '2019-05-20' AND '2019-06-16' THEN 'before'
            WHEN "week_date" BETWEEN '2019-06-17' AND '2019-07-14' THEN 'after'
        END,
        "sales"
    FROM "cleaned_weekly_sales"
    WHERE "calendar_year" = 2019
      AND "week_date" BETWEEN '2019-05-20' AND '2019-07-14'

    UNION ALL
    /* --------------------------- 2020 --------------------------- */
    SELECT 
        "calendar_year",
        CASE 
            WHEN "week_date" BETWEEN '2020-05-18' AND '2020-06-14' THEN 'before'
            WHEN "week_date" BETWEEN '2020-06-15' AND '2020-07-12' THEN 'after'
        END,
        "sales"
    FROM "cleaned_weekly_sales"
    WHERE "calendar_year" = 2020
      AND "week_date" BETWEEN '2020-05-18' AND '2020-07-12'
), aggregated AS (
    SELECT 
        "calendar_year",
        period,
        SUM("sales") AS total_sales
    FROM period_sales
    GROUP BY "calendar_year", period
)
SELECT 
    bef."calendar_year",
    bef.total_sales AS sales_before,
    aft.total_sales AS sales_after,
    ROUND(
        (aft.total_sales - bef.total_sales) * 100.0 / bef.total_sales,
        4
    ) AS pct_change
FROM aggregated bef
JOIN aggregated aft
  ON bef."calendar_year" = aft."calendar_year"
WHERE bef.period = 'before'
  AND aft.period = 'after'
ORDER BY bef."calendar_year";