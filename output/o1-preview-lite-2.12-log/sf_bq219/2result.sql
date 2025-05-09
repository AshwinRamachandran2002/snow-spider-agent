WITH total_volume_per_month AS (
    SELECT DATE_TRUNC('month', "date") AS "month",
           SUM("volume_sold_liters") AS "total_volume"
    FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
    WHERE "date" >= '2022-01-01' AND "date" < DATE_TRUNC('month', CURRENT_DATE)
    GROUP BY "month"
),
category_volume_per_month AS (
    SELECT DATE_TRUNC('month', "date") AS "month",
           "category",
           "category_name",
           SUM("volume_sold_liters") AS "category_volume"
    FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
    WHERE "date" >= '2022-01-01' AND "date" < DATE_TRUNC('month', CURRENT_DATE)
    GROUP BY "month", "category", "category_name"
),
category_percentage_per_month AS (
    SELECT c."month",
           c."category",
           c."category_name",
           c."category_volume" / t."total_volume" AS "percentage"
    FROM category_volume_per_month c
    JOIN total_volume_per_month t ON c."month" = t."month"
),
category_stats AS (
    SELECT "category",
           "category_name",
           COUNT(*) AS "months_with_data",
           AVG("percentage") AS "average_monthly_percentage"
    FROM category_percentage_per_month
    GROUP BY "category", "category_name"
    HAVING AVG("percentage") >= 0.01 AND COUNT(*) >= 24
),
selected_category_percentages AS (
    SELECT cpm."month",
           cpm."category",
           cpm."category_name",
           cpm."percentage"
    FROM category_percentage_per_month cpm
    WHERE cpm."category" IN (SELECT "category" FROM category_stats)
)
SELECT
    a."category_name" AS "Category1",
    b."category_name" AS "Category2"
FROM selected_category_percentages a
JOIN selected_category_percentages b ON a."month" = b."month" AND a."category" < b."category"
GROUP BY a."category", a."category_name", b."category", b."category_name"
ORDER BY CORR(a."percentage", b."percentage") ASC
LIMIT 1;