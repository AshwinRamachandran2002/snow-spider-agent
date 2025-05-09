WITH italian_profit AS (
    SELECT
        s."cust_id",
        SUM(s."amount_sold" - (c."unit_cost" * s."quantity_sold")) AS profit
    FROM "sales"     AS s
    JOIN "times"     AS t  ON s."time_id" = t."time_id"
    JOIN "customers" AS cu ON s."cust_id" = cu."cust_id"
    JOIN "countries" AS co ON cu."country_id" = co."country_id"
    JOIN "costs"     AS c  ON c."prod_id"    = s."prod_id"
                          AND c."time_id"    = s."time_id"
                          AND c."promo_id"   = s."promo_id"
                          AND c."channel_id" = s."channel_id"
    WHERE co."country_name" = 'Italy'
      AND t."calendar_month_name" = 'December'
      AND t."calendar_year"       = 2021
    GROUP BY s."cust_id"
),
ranked AS (
    SELECT
        cust_id,
        profit,
        NTILE(10) OVER (ORDER BY profit DESC) AS profit_tier
    FROM italian_profit
)
SELECT
    profit_tier,
    ROUND(MIN(profit), 4) AS lowest_profit,
    ROUND(MAX(profit), 4) AS highest_profit
FROM ranked
GROUP BY profit_tier
ORDER BY profit_tier;