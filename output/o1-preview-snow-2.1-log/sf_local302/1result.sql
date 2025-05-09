WITH region_pct_change AS (
    SELECT
        'Region: ' || "region" as "Attribute",
        ((avg_after - avg_before)/NULLIF(avg_before,0)) * 100 as "Average_Percentage_Change"
    FROM (
        SELECT
            "region",
            AVG(CASE WHEN "calendar_year" = 2020 AND "week_number" BETWEEN 13 AND 24 THEN "sales" END) as avg_before,
            AVG(CASE WHEN "calendar_year" = 2020 AND "week_number" BETWEEN 26 AND 37 THEN "sales" END) as avg_after
        FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
        GROUP BY "region"
    ) sub
    WHERE avg_before IS NOT NULL AND avg_after IS NOT NULL
),
platform_pct_change AS (
    SELECT
        'Platform: ' || "platform" as "Attribute",
        ((avg_after - avg_before)/NULLIF(avg_before,0)) * 100 as "Average_Percentage_Change"
    FROM (
        SELECT
            "platform",
            AVG(CASE WHEN "calendar_year" = 2020 AND "week_number" BETWEEN 13 AND 24 THEN "sales" END) as avg_before,
            AVG(CASE WHEN "calendar_year" = 2020 AND "week_number" BETWEEN 26 AND 37 THEN "sales" END) as avg_after
        FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
        GROUP BY "platform"
    ) sub
    WHERE avg_before IS NOT NULL AND avg_after IS NOT NULL
),
age_band_pct_change AS (
    SELECT
        'Age Band: ' || "age_band" as "Attribute",
        ((avg_after - avg_before)/NULLIF(avg_before,0)) * 100 as "Average_Percentage_Change"
    FROM (
        SELECT
            "age_band",
            AVG(CASE WHEN "calendar_year" = 2020 AND "week_number" BETWEEN 13 AND 24 THEN "sales" END) as avg_before,
            AVG(CASE WHEN "calendar_year" = 2020 AND "week_number" BETWEEN 26 AND 37 THEN "sales" END) as avg_after
        FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
        GROUP BY "age_band"
    ) sub
    WHERE avg_before IS NOT NULL AND avg_after IS NOT NULL
),
demographic_pct_change AS (
    SELECT
        'Demographic: ' || "demographic" as "Attribute",
        ((avg_after - avg_before)/NULLIF(avg_before,0)) * 100 as "Average_Percentage_Change"
    FROM (
        SELECT
            "demographic",
            AVG(CASE WHEN "calendar_year" = 2020 AND "week_number" BETWEEN 13 AND 24 THEN "sales" END) as avg_before,
            AVG(CASE WHEN "calendar_year" = 2020 AND "week_number" BETWEEN 26 AND 37 THEN "sales" END) as avg_after
        FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
        GROUP BY "demographic"
    ) sub
    WHERE avg_before IS NOT NULL AND avg_after IS NOT NULL
),
customer_type_pct_change AS (
    SELECT
        'Customer Type: ' || "customer_type" as "Attribute",
        ((avg_after - avg_before)/NULLIF(avg_before,0)) * 100 as "Average_Percentage_Change"
    FROM (
        SELECT
            "customer_type",
            AVG(CASE WHEN "calendar_year" = 2020 AND "week_number" BETWEEN 13 AND 24 THEN "sales" END) as avg_before,
            AVG(CASE WHEN "calendar_year" = 2020 AND "week_number" BETWEEN 26 AND 37 THEN "sales" END) as avg_after
        FROM BANK_SALES_TRADING.BANK_SALES_TRADING.CLEANED_WEEKLY_SALES
        GROUP BY "customer_type"
    ) sub
    WHERE avg_before IS NOT NULL AND avg_after IS NOT NULL
),
combined AS (
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
SELECT "Attribute", ROUND("Average_Percentage_Change",4) as "Average_Percentage_Change"
FROM combined
ORDER BY "Average_Percentage_Change" ASC
LIMIT 1;