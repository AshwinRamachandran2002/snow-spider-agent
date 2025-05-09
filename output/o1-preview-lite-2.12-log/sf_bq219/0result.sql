WITH months AS (
    SELECT DISTINCT DATE_TRUNC('month', "date") AS "month"
    FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
    WHERE "date" >= '2022-01-01' AND "date" < DATE_TRUNC('month', CURRENT_DATE())
),
total_monthly AS (
    SELECT DATE_TRUNC('month', "date") AS "month",
           SUM("bottles_sold") AS "total_bottles_sold"
    FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
    WHERE "date" >= '2022-01-01' AND "date" < DATE_TRUNC('month', CURRENT_DATE())
    GROUP BY "month"
),
category_monthly AS (
    SELECT DATE_TRUNC('month', "date") AS "month",
           "category",
           "category_name",
           SUM("bottles_sold") AS "monthly_bottles_sold"
    FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
    WHERE "date" >= '2022-01-01' AND "date" < DATE_TRUNC('month', CURRENT_DATE())
    GROUP BY "month", "category", "category_name"
),
percentage_data AS (
    SELECT
        cm."month",
        cm."category",
        cm."category_name",
        (cm."monthly_bottles_sold" / tm."total_bottles_sold") * 100 AS "percentage_contribution"
    FROM category_monthly cm
    JOIN total_monthly tm ON cm."month" = tm."month"
),
qualifying_categories AS (
    SELECT
        "category",
        "category_name",
        AVG("percentage_contribution") AS "average_percentage",
        COUNT(DISTINCT "month") AS "months_with_sales"
    FROM percentage_data
    GROUP BY "category", "category_name"
    HAVING AVG("percentage_contribution") >= 1 AND COUNT(DISTINCT "month") >= 24
),
category_month_matrix AS (
    SELECT
        m."month",
        qc."category",
        qc."category_name",
        COALESCE(pd."percentage_contribution", 0) AS "percentage_contribution"
    FROM months m
    CROSS JOIN qualifying_categories qc
    LEFT JOIN percentage_data pd ON pd."month" = m."month" AND pd."category" = qc."category"
),
correlations AS (
    SELECT
        c1."category" AS "category1",
        c1."category_name" AS "category_name1",
        c2."category" AS "category2",
        c2."category_name" AS "category_name2",
        CORR(c1."percentage_contribution", c2."percentage_contribution") AS "correlation_coefficient"
    FROM category_month_matrix c1
    JOIN category_month_matrix c2
        ON c1."month" = c2."month" AND c1."category" < c2."category"
    GROUP BY c1."category", c1."category_name", c2."category", c2."category_name"
)
SELECT
    "category_name1" AS "Category1",
    "category_name2" AS "Category2"
FROM correlations
ORDER BY ABS("correlation_coefficient") ASC NULLS LAST
LIMIT 1;