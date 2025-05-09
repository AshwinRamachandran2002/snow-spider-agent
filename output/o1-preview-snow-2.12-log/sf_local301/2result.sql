WITH sales_data AS (
    SELECT
        "calendar_year",
        TO_DATE("week_date") AS "week_start_date",
        DATEADD('day', 6, TO_DATE("week_date")) AS "week_end_date",
        "sales"
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CLEANED_WEEKLY_SALES"
),
june_15_dates AS (
    SELECT
        DISTINCT "calendar_year",
        TO_DATE(CONCAT("calendar_year", '-06-15')) AS "june_15"
    FROM sales_data
),
periods AS (
    SELECT
        sd."calendar_year",
        sd."sales",
        CASE
            WHEN sd."week_end_date" < j."june_15"
                 AND sd."week_end_date" >= DATEADD('day', -28, j."june_15") THEN 'before'
            WHEN sd."week_start_date" > j."june_15"
                 AND sd."week_start_date" <= DATEADD('day', 28, j."june_15") THEN 'after'
            ELSE NULL
        END AS "period"
    FROM sales_data sd
    JOIN june_15_dates j ON sd."calendar_year" = j."calendar_year"
)
SELECT
    p1."calendar_year" AS "Year",
    ROUND(((p1."after_sales" - p1."before_sales") / p1."before_sales") * 100, 4) AS "Percentage_Change"
FROM (
    SELECT
        "calendar_year",
        SUM(CASE WHEN "period" = 'before' THEN "sales" ELSE 0 END) AS "before_sales",
        SUM(CASE WHEN "period" = 'after' THEN "sales" ELSE 0 END) AS "after_sales"
        FROM periods
    WHERE "period" IN ('before', 'after')
    GROUP BY "calendar_year"
) p1
ORDER BY p1."calendar_year";