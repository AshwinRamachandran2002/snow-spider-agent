WITH percentage_changes AS (
    SELECT 'region' AS Attribute, "region" AS Value,
        ((AVG(CASE WHEN "week_date_formatted" >= '2020-06-15' THEN "sales" END) -
          AVG(CASE WHEN "week_date_formatted" < '2020-06-15' THEN "sales" END)) /
          AVG(CASE WHEN "week_date_formatted" < '2020-06-15' THEN "sales" END) * 100
        ) AS Average_Percentage_Change_in_Sales
    FROM "cleaned_weekly_sales"
    GROUP BY "region"
    UNION ALL
    SELECT 'platform' AS Attribute, "platform" AS Value,
        ((AVG(CASE WHEN "week_date_formatted" >= '2020-06-15' THEN "sales" END) -
          AVG(CASE WHEN "week_date_formatted" < '2020-06-15' THEN "sales" END)) /
          AVG(CASE WHEN "week_date_formatted" < '2020-06-15' THEN "sales" END) * 100
        ) AS Average_Percentage_Change_in_Sales
    FROM "cleaned_weekly_sales"
    GROUP BY "platform"
    UNION ALL
    SELECT 'age_band' AS Attribute, "age_band" AS Value,
        ((AVG(CASE WHEN "week_date_formatted" >= '2020-06-15' THEN "sales" END) -
          AVG(CASE WHEN "week_date_formatted" < '2020-06-15' THEN "sales" END)) /
          AVG(CASE WHEN "week_date_formatted" < '2020-06-15' THEN "sales" END) * 100
        ) AS Average_Percentage_Change_in_Sales
    FROM "cleaned_weekly_sales"
    GROUP BY "age_band"
    UNION ALL
    SELECT 'demographic' AS Attribute, "demographic" AS Value,
        ((AVG(CASE WHEN "week_date_formatted" >= '2020-06-15' THEN "sales" END) -
          AVG(CASE WHEN "week_date_formatted" < '2020-06-15' THEN "sales" END)) /
          AVG(CASE WHEN "week_date_formatted" < '2020-06-15' THEN "sales" END) * 100
        ) AS Average_Percentage_Change_in_Sales
    FROM "cleaned_weekly_sales"
    GROUP BY "demographic"
    UNION ALL
    SELECT 'customer_type' AS Attribute, "customer_type" AS Value,
        ((AVG(CASE WHEN "week_date_formatted" >= '2020-06-15' THEN "sales" END) -
          AVG(CASE WHEN "week_date_formatted" < '2020-06-15' THEN "sales" END)) /
          AVG(CASE WHEN "week_date_formatted" < '2020-06-15' THEN "sales" END) * 100
        ) AS Average_Percentage_Change_in_Sales
    FROM "cleaned_weekly_sales"
    GROUP BY "customer_type"
)
SELECT Attribute, Value, ROUND(Average_Percentage_Change_in_Sales, 4) AS Average_Percentage_Change_in_Sales
FROM percentage_changes
ORDER BY Average_Percentage_Change_in_Sales ASC
LIMIT 1;