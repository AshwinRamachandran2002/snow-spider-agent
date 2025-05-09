WITH profit_per_cust AS (   -- total December-2021 profit per Italian customer
    SELECT  s."cust_id",
            SUM(s."amount_sold" - c."unit_cost" * s."quantity_sold") AS total_profit
    FROM    "sales"  AS s
    JOIN    "costs"  AS c
           ON s."prod_id" = c."prod_id"
          AND s."time_id" = c."time_id"
    WHERE   s."time_id" BETWEEN '2021-12-01' AND '2021-12-31'
      AND   s."cust_id" IN (                           -- Italian customers only
                SELECT cu."cust_id"
                FROM   "customers" AS cu
                JOIN   "countries"  AS co
                       ON cu."country_id" = co."country_id"
                WHERE  co."country_name" = 'Italy'
            )
    GROUP BY s."cust_id"
),
tiered AS (               -- split customers into 10 equal profit tiers
    SELECT  "cust_id",
            total_profit,
            NTILE(10) OVER (ORDER BY total_profit DESC) AS profit_tier
    FROM    profit_per_cust
)
SELECT  profit_tier,
        MAX(total_profit) AS highest_profit,
        MIN(total_profit) AS lowest_profit
FROM    tiered
GROUP BY profit_tier
ORDER BY profit_tier;