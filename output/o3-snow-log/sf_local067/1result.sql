WITH profit_per_customer AS (   -- 1) Profit generated in Dec-2021 by each Italian customer
    SELECT
        s."cust_id",
        SUM( s."amount_sold" 
             - COALESCE(cst."unit_cost",0) * s."quantity_sold" )      AS "profit_dec21"
    FROM "COMPLEX_ORACLE"."COMPLEX_ORACLE"."SALES"      s
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."TIMES"      t   ON s."time_id" = t."time_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."CUSTOMERS"  cu  ON s."cust_id" = cu."cust_id"
    JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COUNTRIES"  co  ON cu."country_id" = co."country_id"
    LEFT JOIN "COMPLEX_ORACLE"."COMPLEX_ORACLE"."COSTS" cst ON s."prod_id"   = cst."prod_id"
                                                           AND s."time_id"   = cst."time_id"
                                                           AND s."channel_id"= cst."channel_id"
    WHERE co."country_name"         = 'Italy'
      AND t."calendar_year"         = 2021
      AND t."calendar_month_number" = 12
    GROUP BY s."cust_id"
), tiered AS (                     -- 2) Place customers into 10 equal-sized tiers
    SELECT
        "cust_id",
        "profit_dec21",
        NTILE(10) OVER (ORDER BY "profit_dec21")        AS "tier"
    FROM profit_per_customer
)
SELECT                              -- 3) Lowest & highest profit within each tier
    "tier",
    MIN(ROUND("profit_dec21",4))    AS "lowest_profit",
    MAX(ROUND("profit_dec21",4))    AS "highest_profit"
FROM tiered
GROUP BY "tier"
ORDER BY "tier";