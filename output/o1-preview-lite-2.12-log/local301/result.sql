SELECT before_sales."calendar_year" AS Year,
       ROUND(((after_sales.total_sales - before_sales.total_sales) * 100.0 / before_sales.total_sales), 4) AS Percentage_Change_Sales
FROM (
    SELECT "calendar_year", SUM("sales") AS total_sales
    FROM "cleaned_weekly_sales"
    WHERE "calendar_year" IN (2018, 2019, 2020)
      AND "week_number" BETWEEN 21 AND 24
    GROUP BY "calendar_year"
) AS before_sales
JOIN (
    SELECT "calendar_year", SUM("sales") AS total_sales
    FROM "cleaned_weekly_sales"
    WHERE "calendar_year" IN (2018, 2019, 2020)
      AND "week_number" BETWEEN 25 AND 28
    GROUP BY "calendar_year"
) AS after_sales
ON before_sales."calendar_year" = after_sales."calendar_year";