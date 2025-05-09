WITH total_monthly_sales AS (
    SELECT
        DATE_TRUNC('month', "date") AS "month",
        SUM("volume_sold_liters") AS total_monthly_volume
    FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
    WHERE "date" BETWEEN '2018-05-01' AND '2020-04-30'
    GROUP BY "month"
),
category_monthly_sales AS (
    SELECT
        "category",
        "category_name",
        DATE_TRUNC('month', "date") AS "month",
        SUM("volume_sold_liters") AS category_monthly_volume
    FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
    WHERE "date" BETWEEN '2018-05-01' AND '2020-04-30'
    GROUP BY "category", "category_name", "month"
),
category_percentage AS (
    SELECT
        cms."category",
        cms."category_name",
        cms."month",
        (cms.category_monthly_volume / tms.total_monthly_volume) * 100 AS monthly_percentage
    FROM category_monthly_sales cms
    JOIN total_monthly_sales tms ON cms."month" = tms."month"
),
category_average_percentage AS (
    SELECT
        "category",
        "category_name",
        AVG(monthly_percentage) AS average_percentage
    FROM category_percentage
    GROUP BY "category", "category_name"
),
categories_over_1pct AS (
    SELECT *
    FROM category_average_percentage
    WHERE average_percentage >= 1
),
category_pairs AS (
    SELECT
        c1."category" AS category1,
        c1."category_name" AS category_name1,
        c2."category" AS category2,
        c2."category_name" AS category_name2
    FROM categories_over_1pct c1
    JOIN categories_over_1pct c2 ON c1."category" < c2."category"
),
correlations AS (
    SELECT
        cp.category_name1 AS "Category_1",
        cp.category_name2 AS "Category_2",
        CORR(cp1.monthly_percentage, cp2.monthly_percentage) AS "Lowest_Pearson_Correlation_Coefficient"
    FROM category_pairs cp
    JOIN category_percentage cp1 ON cp.category1 = cp1."category"
    JOIN category_percentage cp2 ON cp.category2 = cp2."category" AND cp1."month" = cp2."month"
    GROUP BY cp.category_name1, cp.category_name2
    HAVING COUNT(*) = 24
)
SELECT
    "Category_1",
    "Category_2",
    ROUND("Lowest_Pearson_Correlation_Coefficient", 4) AS "Lowest_Pearson_Correlation_Coefficient"
FROM correlations
ORDER BY "Lowest_Pearson_Correlation_Coefficient" ASC NULLS LAST
LIMIT 1;