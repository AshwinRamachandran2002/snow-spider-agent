SELECT
    Attribute,
    Value,
    ((sales_after - sales_before) * 100.0 / sales_before) AS Average_Percentage_Change_in_Sales
FROM (
    SELECT 
        'region' AS Attribute,
        "region" AS Value,
        SUM(CASE WHEN "week_number" BETWEEN 13 AND 24 THEN "sales" ELSE 0 END) AS sales_before,
        SUM(CASE WHEN "week_number" BETWEEN 25 AND 36 THEN "sales" ELSE 0 END) AS sales_after
    FROM 
        "cleaned_weekly_sales"
    WHERE
        "calendar_year" = 2020
    GROUP BY
        "region"

    UNION ALL

    SELECT 
        'platform' AS Attribute,
        "platform" AS Value,
        SUM(CASE WHEN "week_number" BETWEEN 13 AND 24 THEN "sales" ELSE 0 END) AS sales_before,
        SUM(CASE WHEN "week_number" BETWEEN 25 AND 36 THEN "sales" ELSE 0 END) AS sales_after
    FROM 
        "cleaned_weekly_sales"
    WHERE
        "calendar_year" = 2020
    GROUP BY
        "platform"

    UNION ALL

    SELECT 
        'age_band' AS Attribute,
        "age_band" AS Value,
        SUM(CASE WHEN "week_number" BETWEEN 13 AND 24 THEN "sales" ELSE 0 END) AS sales_before,
        SUM(CASE WHEN "week_number" BETWEEN 25 AND 36 THEN "sales" ELSE 0 END) AS sales_after
    FROM 
        "cleaned_weekly_sales"
    WHERE
        "calendar_year" = 2020
    GROUP BY
        "age_band"

    UNION ALL

    SELECT 
        'demographic' AS Attribute,
        "demographic" AS Value,
        SUM(CASE WHEN "week_number" BETWEEN 13 AND 24 THEN "sales" ELSE 0 END) AS sales_before,
        SUM(CASE WHEN "week_number" BETWEEN 25 AND 36 THEN "sales" ELSE 0 END) AS sales_after
    FROM 
        "cleaned_weekly_sales"
    WHERE
        "calendar_year" = 2020
    GROUP BY
        "demographic"

    UNION ALL

    SELECT 
        'customer_type' AS Attribute,
        "customer_type" AS Value,
        SUM(CASE WHEN "week_number" BETWEEN 13 AND 24 THEN "sales" ELSE 0 END) AS sales_before,
        SUM(CASE WHEN "week_number" BETWEEN 25 AND 36 THEN "sales" ELSE 0 END) AS sales_after
    FROM 
        "cleaned_weekly_sales"
    WHERE
        "calendar_year" = 2020
    GROUP BY
        "customer_type"
) t
ORDER BY
    Average_Percentage_Change_in_Sales ASC
LIMIT 1;