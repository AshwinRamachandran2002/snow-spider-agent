WITH monthly_sales AS (
    SELECT
        DATE_TRUNC('month', "date") AS "Month",
        SUM("volume_sold_liters") AS "Total_Monthly_Volume_Liters"
    FROM
        "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
    WHERE
        "date" >= DATEADD(month, -24, DATE '2020-04-01')
        AND "date" < DATE '2020-05-01'
    GROUP BY
        DATE_TRUNC('month', "date")
),
category_monthly_sales AS (
    SELECT
        DATE_TRUNC('month', "date") AS "Month",
        "category",
        "category_name",
        SUM("volume_sold_liters") AS "Category_Monthly_Volume_Liters"
    FROM
        "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
    WHERE
        "date" >= DATEADD(month, -24, DATE '2020-04-01')
        AND "date" < DATE '2020-05-01'
    GROUP BY
        DATE_TRUNC('month', "date"),
        "category",
        "category_name"
),
category_monthly_percentage AS (
    SELECT
        cms."Month",
        cms."category",
        cms."category_name",
        (cms."Category_Monthly_Volume_Liters" / ms."Total_Monthly_Volume_Liters") * 100 AS "Monthly_Percentage"
    FROM
        category_monthly_sales cms
        JOIN monthly_sales ms ON cms."Month" = ms."Month"
),
category_average_percentage AS (
    SELECT
        "category",
        "category_name",
        AVG("Monthly_Percentage") AS "Average_Percentage"
    FROM
        category_monthly_percentage
    GROUP BY
        "category",
        "category_name"
),
selected_categories AS (
    SELECT
        "category",
        "category_name"
    FROM
        category_average_percentage
    WHERE
        "Average_Percentage" >= 1.0
),
category_percentages AS (
    SELECT
        cmp."category",
        cmp."category_name",
        cmp."Month",
        cmp."Monthly_Percentage"
    FROM
        category_monthly_percentage cmp
        JOIN selected_categories sc ON cmp."category" = sc."category"
),
paired_percentages AS (
    SELECT
        cp1."category_name" AS "Category1",
        cp2."category_name" AS "Category2",
        cp1."Month",
        cp1."Monthly_Percentage" AS "Percentage1",
        cp2."Monthly_Percentage" AS "Percentage2"
    FROM
        category_percentages cp1
        JOIN category_percentages cp2
            ON cp1."Month" = cp2."Month"
            AND cp1."category" < cp2."category"
),
correlation_coefficients AS (
    SELECT
        "Category1",
        "Category2",
        CORR("Percentage1", "Percentage2") AS "Pearson_Correlation_Coefficient"
    FROM
        paired_percentages
    GROUP BY
        "Category1",
        "Category2"
)
SELECT
    "Category1",
    "Category2",
    ROUND("Pearson_Correlation_Coefficient", 4) AS "Pearson_Correlation_Coefficient"
FROM
    correlation_coefficients
ORDER BY
    "Pearson_Correlation_Coefficient" ASC
LIMIT 1;