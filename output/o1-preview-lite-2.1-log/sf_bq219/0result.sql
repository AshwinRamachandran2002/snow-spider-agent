WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', "date") AS "month",
        SUM("volume_sold_liters") AS "total_monthly_volume"
    FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
    WHERE "date" >= DATEADD('month', -24, (SELECT MAX("date") FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"))
    GROUP BY "month"
),
category_monthly_sales AS (
    SELECT
        DATE_TRUNC('month', "date") AS "month",
        "category",
        SUM("volume_sold_liters") AS "category_monthly_volume"
    FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
    WHERE "date" >= DATEADD('month', -24, (SELECT MAX("date") FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"))
    GROUP BY "month", "category"
),
category_monthly_percentage AS (
    SELECT
        cms."month",
        cms."category",
        cms."category_monthly_volume" / ms."total_monthly_volume" * 100 AS "monthly_percentage"
    FROM category_monthly_sales cms
    JOIN monthly_sales ms ON cms."month" = ms."month"
),
category_average_percentage AS (
    SELECT
        "category",
        AVG("monthly_percentage") AS "average_percentage"
    FROM category_monthly_percentage
    GROUP BY "category"
),
selected_categories AS (
    SELECT "category"
    FROM category_average_percentage
    WHERE "average_percentage" >= 1
),
selected_category_monthly_percentage AS (
    SELECT
        cmp."month",
        cmp."category",
        cmp."monthly_percentage"
    FROM category_monthly_percentage cmp
    WHERE cmp."category" IN (SELECT "category" FROM selected_categories)
),
category_pairs AS (
    SELECT
        sc1."category" AS "category1",
        sc2."category" AS "category2"
    FROM selected_categories sc1
    JOIN selected_categories sc2 ON sc1."category" < sc2."category"
),
category_correlations AS (
    SELECT
        cp."category1",
        cp."category2",
        ROUND(CORR(cmp1."monthly_percentage", cmp2."monthly_percentage"), 4) AS "pearson_correlation_coefficient"
    FROM category_pairs cp
    JOIN selected_category_monthly_percentage cmp1 ON cp."category1" = cmp1."category"
    JOIN selected_category_monthly_percentage cmp2 ON cp."category2" = cmp2."category" AND cmp1."month" = cmp2."month"
    GROUP BY cp."category1", cp."category2"
)
SELECT
    cc."category1",
    cc."category2",
    cc."pearson_correlation_coefficient"
FROM category_correlations cc
ORDER BY cc."pearson_correlation_coefficient" ASC NULLS LAST
LIMIT 1;