WITH italian_customer_profits AS (
    SELECT
        s."cust_id",
        SUM(s."amount_sold" - s."quantity_sold" * c."unit_cost") AS "total_profit"
    FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES"      s
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COSTS"      c
         ON  s."prod_id"   = c."prod_id"
         AND s."time_id"   = c."time_id"
         AND s."channel_id"= c."channel_id"
         AND s."promo_id"  = c."promo_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES"      t
         ON s."time_id" = t."time_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS"  cu
         ON s."cust_id" = cu."cust_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES"  co
         ON cu."country_id" = co."country_id"
    WHERE co."country_name"      = 'Italy'
      AND t."calendar_year"      = 2021
      AND t."calendar_month_number" = 12
    GROUP BY s."cust_id"
),
tiered_profits AS (
    SELECT
        "cust_id",
        "total_profit",
        NTILE(10) OVER (ORDER BY "total_profit" DESC) AS "profit_tier"
    FROM italian_customer_profits
)
SELECT
    "profit_tier"                                   AS "tier",
    ROUND(MAX("total_profit"), 4)                   AS "highest_profit",
    ROUND(MIN("total_profit"), 4)                   AS "lowest_profit"
FROM tiered_profits
GROUP BY "profit_tier"
ORDER BY "profit_tier";