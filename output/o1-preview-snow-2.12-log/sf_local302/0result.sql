WITH 
changes AS (
    SELECT 
        'Region' AS Attribute_Category,
        "region" AS Attribute_Value,
        ((AVG(CASE WHEN "week_date" BETWEEN '2020-06-15' AND '2020-09-07' THEN "sales" END) - 
          AVG(CASE WHEN "week_date" BETWEEN '2020-03-23' AND '2020-06-14' THEN "sales" END)) /
          NULLIF(AVG(CASE WHEN "week_date" BETWEEN '2020-03-23' AND '2020-06-14' THEN "sales" END),0)) * 100 AS Average_Percentage_Change
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CLEANED_WEEKLY_SALES"
    GROUP BY "region"
    UNION ALL
    SELECT 
        'Platform' AS Attribute_Category,
        "platform" AS Attribute_Value,
        ((AVG(CASE WHEN "week_date" BETWEEN '2020-06-15' AND '2020-09-07' THEN "sales" END) - 
          AVG(CASE WHEN "week_date" BETWEEN '2020-03-23' AND '2020-06-14' THEN "sales" END)) /
          NULLIF(AVG(CASE WHEN "week_date" BETWEEN '2020-03-23' AND '2020-06-14' THEN "sales" END),0)) * 100
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CLEANED_WEEKLY_SALES"
    GROUP BY "platform"
    UNION ALL
    SELECT 
        'Age Band' AS Attribute_Category,
        "age_band" AS Attribute_Value,
        ((AVG(CASE WHEN "week_date" BETWEEN '2020-06-15' AND '2020-09-07' THEN "sales" END) - 
          AVG(CASE WHEN "week_date" BETWEEN '2020-03-23' AND '2020-06-14' THEN "sales" END)) /
          NULLIF(AVG(CASE WHEN "week_date" BETWEEN '2020-03-23' AND '2020-06-14' THEN "sales" END),0)) * 100
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CLEANED_WEEKLY_SALES"
    GROUP BY "age_band"
    UNION ALL
    SELECT 
        'Demographic' AS Attribute_Category,
        "demographic" AS Attribute_Value,
        ((AVG(CASE WHEN "week_date" BETWEEN '2020-06-15' AND '2020-09-07' THEN "sales" END) - 
          AVG(CASE WHEN "week_date" BETWEEN '2020-03-23' AND '2020-06-14' THEN "sales" END)) /
          NULLIF(AVG(CASE WHEN "week_date" BETWEEN '2020-03-23' AND '2020-06-14' THEN "sales" END),0)) * 100
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CLEANED_WEEKLY_SALES"
    GROUP BY "demographic"
    UNION ALL
    SELECT 
        'Customer Type' AS Attribute_Category,
        "customer_type" AS Attribute_Value,
        ((AVG(CASE WHEN "week_date" BETWEEN '2020-06-15' AND '2020-09-07' THEN "sales" END) - 
          AVG(CASE WHEN "week_date" BETWEEN '2020-03-23' AND '2020-06-14' THEN "sales" END)) /
          NULLIF(AVG(CASE WHEN "week_date" BETWEEN '2020-03-23' AND '2020-06-14' THEN "sales" END),0)) * 100
    FROM "BANK_SALES_TRADING"."BANK_SALES_TRADING"."CLEANED_WEEKLY_SALES"
    GROUP BY "customer_type"
)
SELECT 
    CONCAT(Attribute_Category, ' - ', Attribute_Value) AS "Attribute",
    ROUND(Average_Percentage_Change,4) AS "Average_Percentage_Change"
FROM changes
ORDER BY Average_Percentage_Change ASC
LIMIT 1;