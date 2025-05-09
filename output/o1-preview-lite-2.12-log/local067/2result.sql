WITH customer_profits AS (
    SELECT s."cust_id",
           SUM(ROUND(s."amount_sold" - s."quantity_sold" * cst."unit_cost", 4)) AS total_profit
    FROM "sales" s
    JOIN "costs" cst ON s."prod_id" = cst."prod_id"
                     AND s."time_id" = cst."time_id"
                     AND s."promo_id" = cst."promo_id"
                     AND s."channel_id" = cst."channel_id"
    JOIN "customers" c ON s."cust_id" = c."cust_id"
    JOIN "countries" co ON c."country_id" = co."country_id"
    JOIN "times" t ON s."time_id" = t."time_id"
    WHERE co."country_name" = 'Italy'
      AND t."calendar_month_number" = 12
      AND t."calendar_year" = 2021
    GROUP BY s."cust_id"
)
SELECT
    tier,
    ROUND(MAX(total_profit), 4) AS Highest_Profit,
    ROUND(MIN(total_profit), 4) AS Lowest_Profit
FROM (
    SELECT
        "cust_id",
        total_profit,
        NTILE(10) OVER (ORDER BY total_profit DESC) AS tier
    FROM customer_profits
)
GROUP BY tier
ORDER BY tier;