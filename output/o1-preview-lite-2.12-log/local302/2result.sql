WITH 
    region_pct_change AS (
        SELECT 'region' AS Attribute, region AS Value,
            ((AVG(CASE WHEN "week_date" BETWEEN '2020-06-15' AND '2020-09-07' THEN sales END) - 
              AVG(CASE WHEN "week_date" BETWEEN '2020-03-23' AND '2020-06-14' THEN sales END)
            ) * 100.0 /
             AVG(CASE WHEN "week_date" BETWEEN '2020-03-23' AND '2020-06-14' THEN sales END)
            ) AS Average_Percentage_Change_in_Sales
        FROM "cleaned_weekly_sales"
        WHERE "week_date" BETWEEN '2020-03-23' AND '2020-09-07'
        GROUP BY region
    ),
    platform_pct_change AS (
        SELECT 'platform' AS Attribute, platform AS Value,
            ((AVG(CASE WHEN "week_date" BETWEEN '2020-06-15' AND '2020-09-07' THEN sales END) - 
              AVG(CASE WHEN "week_date" BETWEEN '2020-03-23' AND '2020-06-14' THEN sales END)
            ) * 100.0 /
             AVG(CASE WHEN "week_date" BETWEEN '2020-03-23' AND '2020-06-14' THEN sales END)
            ) AS Average_Percentage_Change_in_Sales
        FROM "cleaned_weekly_sales"
        WHERE "week_date" BETWEEN '2020-03-23' AND '2020-09-07'
        GROUP BY platform
    ),
    age_band_pct_change AS (
        SELECT 'age_band' AS Attribute, age_band AS Value,
            ((AVG(CASE WHEN "week_date" BETWEEN '2020-06-15' AND '2020-09-07' THEN sales END) - 
              AVG(CASE WHEN "week_date" BETWEEN '2020-03-23' AND '2020-06-14' THEN sales END)
            ) * 100.0 /
             AVG(CASE WHEN "week_date" BETWEEN '2020-03-23' AND '2020-06-14' THEN sales END)
            ) AS Average_Percentage_Change_in_Sales
        FROM "cleaned_weekly_sales"
        WHERE "week_date" BETWEEN '2020-03-23' AND '2020-09-07'
        GROUP BY age_band
    ),
    demographic_pct_change AS (
        SELECT 'demographic' AS Attribute, demographic AS Value,
            ((AVG(CASE WHEN "week_date" BETWEEN '2020-06-15' AND '2020-09-07' THEN sales END) - 
              AVG(CASE WHEN "week_date" BETWEEN '2020-03-23' AND '2020-06-14' THEN sales END)
            ) * 100.0 /
             AVG(CASE WHEN "week_date" BETWEEN '2020-03-23' AND '2020-06-14' THEN sales END)
            ) AS Average_Percentage_Change_in_Sales
        FROM "cleaned_weekly_sales"
        WHERE "week_date" BETWEEN '2020-03-23' AND '2020-09-07'
        GROUP BY demographic
    ),
    customer_type_pct_change AS (
        SELECT 'customer_type' AS Attribute, customer_type AS Value,
            ((AVG(CASE WHEN "week_date" BETWEEN '2020-06-15' AND '2020-09-07' THEN sales END) - 
              AVG(CASE WHEN "week_date" BETWEEN '2020-03-23' AND '2020-06-14' THEN sales END)
            ) * 100.0 /
             AVG(CASE WHEN "week_date" BETWEEN '2020-03-23' AND '2020-06-14' THEN sales END)
            ) AS Average_Percentage_Change_in_Sales
        FROM "cleaned_weekly_sales"
        WHERE "week_date" BETWEEN '2020-03-23' AND '2020-09-07'
        GROUP BY customer_type
    )
    
    SELECT Attribute, Value, ROUND(Average_Percentage_Change_in_Sales, 4) AS Average_Percentage_Change_in_Sales
    FROM (
        SELECT * FROM region_pct_change
        UNION ALL
        SELECT * FROM platform_pct_change
        UNION ALL
        SELECT * FROM age_band_pct_change
        UNION ALL
        SELECT * FROM demographic_pct_change
        UNION ALL
        SELECT * FROM customer_type_pct_change
    )
    ORDER BY Average_Percentage_Change_in_Sales ASC
    LIMIT 1;