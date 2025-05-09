WITH customer_profits AS (
    /* Total December-2021 profit per Italian customer */
    SELECT  s."cust_id",
            SUM( s."quantity_sold" * (cst."unit_price" - cst."unit_cost") ) AS "total_profit"
    FROM    "sales"      AS s
    JOIN    "customers"  AS cu  ON cu."cust_id"    = s."cust_id"
    JOIN    "countries"  AS co  ON co."country_id" = cu."country_id"
    JOIN    "times"      AS t   ON t."time_id"     = s."time_id"
    JOIN    "costs"      AS cst ON cst."prod_id"   = s."prod_id"
                               AND cst."time_id"   = s."time_id"
                               AND cst."promo_id"  = s."promo_id"
                               AND cst."channel_id"= s."channel_id"
    WHERE   co."country_name"        = 'Italy'
      AND   t."calendar_year"        = 2021
      AND   t."calendar_month_number"= 12
    GROUP BY s."cust_id"
),
tiered AS (
    /* Place customers into 10 evenly sized tiers (1 = highest profit) */
    SELECT  "cust_id",
            "total_profit",
            NTILE(10) OVER (ORDER BY "total_profit" DESC) AS "profit_tier"
    FROM    customer_profits
)
SELECT  "profit_tier",
        MIN("total_profit") AS "lowest_profit",
        MAX("total_profit") AS "highest_profit"
FROM    tiered
GROUP BY "profit_tier"
ORDER BY "profit_tier";