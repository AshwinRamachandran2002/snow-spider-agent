WITH italian_customers AS (
    SELECT c."cust_id"
    FROM "customers"   c
    JOIN "countries"  co ON c."country_id" = co."country_id"
    WHERE co."country_name" = 'Italy'
),                                                         -- all Italian customers
dec21_profit_per_cust AS (
    SELECT  s."cust_id",
            SUM( s."amount_sold"
                - COALESCE(ct."unit_cost",0) * s."quantity_sold")           AS profit_dec_2021
    FROM "sales"  s
    JOIN italian_customers ic ON ic."cust_id" = s."cust_id"
    JOIN "times" t            ON t."time_id" = s."time_id"
    LEFT JOIN "costs" ct
           ON  ct."prod_id"   = s."prod_id"
           AND ct."time_id"   = s."time_id"
           AND ct."channel_id"= s."channel_id"
           AND ct."promo_id"  = s."promo_id"
    WHERE t."calendar_month_number" = 12      -- December
      AND t."calendar_year"         = 2021    -- year 2021
    GROUP BY s."cust_id"
),                                                         -- December‑2021 profit for each Italian customer
profits_with_decile AS (
    SELECT  dpc.*,
            /* build 10 equal‑sized tiers (deciles) */
            CAST( ((ROW_NUMBER() OVER (ORDER BY dpc.profit_dec_2021) - 1) * 10)
                  / (COUNT(*) OVER () ) AS INTEGER ) + 1       AS tier
    FROM dec21_profit_per_cust dpc
)
SELECT  tier,
        MIN(profit_dec_2021) AS lowest_profit,
        MAX(profit_dec_2021) AS highest_profit
FROM    profits_with_decile
GROUP BY tier
ORDER BY tier;