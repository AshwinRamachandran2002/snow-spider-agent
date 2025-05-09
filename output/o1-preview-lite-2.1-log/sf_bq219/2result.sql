WITH last_24_months AS (
    SELECT 
        DATE_TRUNC('month', "date") AS "sale_month",
        "category_name",
        SUM("volume_sold_liters") AS "monthly_volume_liters"
    FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"
    WHERE "date" >= DATEADD(month, -24, (SELECT MAX("date") FROM "IOWA_LIQUOR_SALES"."IOWA_LIQUOR_SALES"."SALES"))
    GROUP BY DATE_TRUNC('month', "date"), "category_name"
),
monthly_totals AS (
    SELECT 
        "sale_month",
        SUM("monthly_volume_liters") AS "total_monthly_volume"
    FROM last_24_months
    GROUP BY "sale_month"
),
category_percentages AS (
    SELECT 
        l24."sale_month",
        l24."category_name",
        (l24."monthly_volume_liters" / mt."total_monthly_volume") * 100 AS "percentage_contribution"
    FROM last_24_months l24
    JOIN monthly_totals mt ON l24."sale_month" = mt."sale_month"
),
category_average_percentages AS (
    SELECT
        "category_name",
        AVG("percentage_contribution") AS "average_percentage"
    FROM category_percentages
    GROUP BY "category_name"
    HAVING AVG("percentage_contribution") >= 1
),
filtered_category_percentages AS (
    SELECT
        cp."sale_month",
        cp."category_name",
        cp."percentage_contribution"
    FROM category_percentages cp
    INNER JOIN category_average_percentages cap ON cp."category_name" = cap."category_name"
),
corr_pairs AS (
    SELECT 
        t1."category_name" AS "category1",
        t2."category_name" AS "category2",
        CORR(t1."percentage_contribution", t2."percentage_contribution") AS "correlation_coefficient"
    FROM filtered_category_percentages t1
    JOIN filtered_category_percentages t2 ON t1."sale_month" = t2."sale_month" AND t1."category_name" < t2."category_name"
    GROUP BY t1."category_name", t2."category_name"
),
lowest_correlation AS (
    SELECT 
        "category1",
        "category2",
        ROUND("correlation_coefficient", 4) AS "correlation_coefficient"
    FROM corr_pairs
    ORDER BY "correlation_coefficient" ASC
    LIMIT 1
)
SELECT * FROM lowest_correlation;