WITH latest_month AS (
    SELECT DATE_TRUNC('month', MAX("date")) AS latest_month
    FROM IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
    WHERE "date" <= CURRENT_DATE()
),
start_month AS (
    SELECT DATEADD(month, -23, latest_month) AS start_month
    FROM latest_month
),
monthly_sales AS (
    SELECT
        DATE_TRUNC('month', "date") AS "month",
        "category_name",
        SUM("volume_sold_liters") AS monthly_volume
    FROM
        IOWA_LIQUOR_SALES.IOWA_LIQUOR_SALES.SALES
    WHERE
        "date" >= (SELECT start_month FROM start_month)
        AND "date" <= (SELECT latest_month FROM latest_month)
    GROUP BY
        DATE_TRUNC('month', "date"), "category_name"
),
total_monthly_sales AS (
    SELECT
        "month",
        SUM(monthly_volume) AS total_monthly_volume
    FROM
        monthly_sales
    GROUP BY
        "month"
),
monthly_sales_percentage AS (
    SELECT
        ms."month",
        ms."category_name",
        (ms.monthly_volume / tms.total_monthly_volume) * 100 AS volume_percentage
    FROM
        monthly_sales ms
    JOIN
        total_monthly_sales tms ON ms."month" = tms."month"
),
average_monthly_percentage AS (
    SELECT
        "category_name",
        AVG(volume_percentage) AS average_monthly_percentage
    FROM
        monthly_sales_percentage
    GROUP BY
        "category_name"
),
selected_categories AS (
    SELECT
        "category_name"
    FROM
        average_monthly_percentage
    WHERE
        average_monthly_percentage >= 1
),
filtered_monthly_percentage AS (
    SELECT
        msp."month",
        msp."category_name",
        msp.volume_percentage
    FROM
        monthly_sales_percentage msp
    WHERE
        msp."category_name" IN (SELECT "category_name" FROM selected_categories)
),
category_pairs AS (
    SELECT
        c1."category_name" AS category1,
        c2."category_name" AS category2
    FROM
        selected_categories c1
    JOIN
        selected_categories c2 ON c1."category_name" < c2."category_name"
),
correlation_results AS (
    SELECT
        cp.category1,
        cp.category2,
        CORR(fp1.volume_percentage, fp2.volume_percentage) AS correlation_coefficient
    FROM
        category_pairs cp
    JOIN
        filtered_monthly_percentage fp1 ON fp1."category_name" = cp.category1
    JOIN
        filtered_monthly_percentage fp2 ON fp2."category_name" = cp.category2
            AND fp1."month" = fp2."month"
    GROUP BY
        cp.category1,
        cp.category2
)
SELECT
    category1 AS "Category_1",
    category2 AS "Category_2",
    ROUND(correlation_coefficient, 4) AS "Lowest_Pearson_Correlation_Coefficient"
FROM
    correlation_results
ORDER BY
    correlation_coefficient
LIMIT 1;