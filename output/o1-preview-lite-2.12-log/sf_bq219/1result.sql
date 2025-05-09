WITH monthly_category_volume AS (
    SELECT
        DATE_TRUNC('month', "date") AS "month",
        "category_name",
        SUM("volume_sold_liters") AS "category_volume"
    FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
    WHERE "date" >= '2022-01-01'
      AND "date" < DATE_TRUNC('month', CURRENT_DATE)
    GROUP BY
        DATE_TRUNC('month', "date"),
        "category_name"
),
monthly_total_volume AS (
    SELECT
        DATE_TRUNC('month', "date") AS "month",
        SUM("volume_sold_liters") AS "total_volume"
    FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
    WHERE "date" >= '2022-01-01'
      AND "date" < DATE_TRUNC('month', CURRENT_DATE)
    GROUP BY
        DATE_TRUNC('month', "date")
),
category_monthly_percentage AS (
    SELECT
        mcv."month",
        mcv."category_name",
        (mcv."category_volume" / mtv."total_volume") * 100 AS "percentage"
    FROM monthly_category_volume mcv
    JOIN monthly_total_volume mtv
        ON mcv."month" = mtv."month"
),
category_stats AS (
    SELECT
        "category_name",
        AVG("percentage") AS "avg_percentage",
        COUNT(DISTINCT "month") AS "months_count"
    FROM category_monthly_percentage
    GROUP BY "category_name"
),
filtered_categories AS (
    SELECT
        "category_name"
    FROM category_stats
    WHERE
        "avg_percentage" >= 1
        AND "months_count" >= 24
),
filtered_category_percentage AS (
    SELECT
        cmp."category_name",
        cmp."month",
        cmp."percentage"
    FROM category_monthly_percentage cmp
    WHERE cmp."category_name" IN (SELECT "category_name" FROM filtered_categories)
),
correlations AS (
    SELECT
        fc1."category_name" AS "Category1",
        fc2."category_name" AS "Category2",
        CORR(fc1."percentage", fc2."percentage") AS "Correlation"
    FROM filtered_category_percentage fc1
    JOIN filtered_category_percentage fc2
        ON fc1."month" = fc2."month"
        AND fc1."category_name" < fc2."category_name"
    GROUP BY
        fc1."category_name",
        fc2."category_name"
)
SELECT
    "Category1",
    "Category2"
FROM correlations
ORDER BY "Correlation" ASC NULLS LAST
LIMIT 1;