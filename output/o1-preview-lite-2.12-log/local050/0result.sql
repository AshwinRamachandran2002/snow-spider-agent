WITH monthly_sales AS (
    SELECT
        t."calendar_year",
        t."calendar_month_number" AS "month",
        SUM(s."amount_sold" * cu."to_us") AS total_sales_usd
    FROM "sales" s
    JOIN "customers" c ON s."cust_id" = c."cust_id"
    JOIN "countries" co ON c."country_id" = co."country_id"
    JOIN "times" t ON s."time_id" = t."time_id"
    JOIN "promotions" p ON s."promo_id" = p."promo_id"
    JOIN "channels" ch ON s."channel_id" = ch."channel_id"
    JOIN "currency" cu ON cu."country" = 'France' AND cu."year" = t."calendar_year" AND cu."month" = t."calendar_month_number"
    WHERE co."country_name" = 'France'
      AND t."calendar_year" IN (2019, 2020)
      AND p."promo_total_id" = 1
      AND ch."channel_total_id" = 1
    GROUP BY t."calendar_year", t."calendar_month_number"
),
sales_2019 AS (
    SELECT "month", total_sales_usd
    FROM monthly_sales
    WHERE calendar_year = 2019
),
sales_2020 AS (
    SELECT "month", total_sales_usd
    FROM monthly_sales
    WHERE calendar_year = 2020
),
growth_rates AS (
    SELECT
        s2019."month",
        s2019."total_sales_usd" AS sales_2019_usd,
        s2020."total_sales_usd" AS sales_2020_usd,
        (s2020."total_sales_usd" - s2019."total_sales_usd") * 1.0 / s2019."total_sales_usd" AS growth_rate
    FROM sales_2019 s2019
    JOIN sales_2020 s2020 ON s2019."month" = s2020."month"
),
projected_sales_2021 AS (
    SELECT
        "month",
        sales_2020_usd * (1 + growth_rate) AS projected_sales_2021_usd
    FROM growth_rates
),
ordered_sales AS (
    SELECT
        projected_sales_2021_usd,
        ROW_NUMBER() OVER (ORDER BY projected_sales_2021_usd) AS rn
    FROM projected_sales_2021
)
SELECT
    ROUND(AVG(projected_sales_2021_usd), 4) AS "Median_Average_Monthly_Projected_Sales_USD"
FROM ordered_sales
WHERE rn IN (6, 7);