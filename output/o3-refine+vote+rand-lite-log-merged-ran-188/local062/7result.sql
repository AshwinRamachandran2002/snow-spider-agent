WITH italian_customers AS (
    SELECT  c.cust_id
    FROM    customers  AS c
    JOIN    countries  AS co
           ON c.country_id = co.country_id
    WHERE   co.country_name = 'Italy'
),
cust_profit AS (
    /* total profit per Italian customer in Dec‑2021 */
    SELECT  s.cust_id,
            SUM( s.quantity_sold * (cst.unit_price - cst.unit_cost) ) AS total_profit
    FROM    sales  AS s
    JOIN    costs  AS cst
           ON s.prod_id    = cst.prod_id
          AND s.time_id    = cst.time_id
          AND s.channel_id = cst.channel_id
          AND s.promo_id   = cst.promo_id
    WHERE   s.time_id BETWEEN '2021-12-01' AND '2021-12-31'
      AND   s.cust_id IN (SELECT cust_id FROM italian_customers)
    GROUP BY s.cust_id
),
stats AS (
    /* overall range and width of each of the 10 equal intervals */
    SELECT  MIN(total_profit)                                  AS min_p,
            MAX(total_profit)                                  AS max_p,
            (MAX(total_profit) - MIN(total_profit)) / 10.0     AS w
    FROM    cust_profit
),
bucketed AS (
    /* place each customer into a 0‑based bucket id (0–9) */
    SELECT  cp.cust_id,
            cp.total_profit,
            CASE
                WHEN stats.max_p = stats.min_p         -- all profits equal
                     THEN 9
                ELSE CAST( (cp.total_profit - stats.min_p) / stats.w AS INTEGER )
            END                                         AS raw_bucket_id
    FROM    cust_profit cp
    CROSS JOIN stats
),
final AS (
    /* ensure any round‑off pushes max value into last bucket (id 9) */
    SELECT  CASE 
                WHEN raw_bucket_id >= 10 THEN 9 
                ELSE raw_bucket_id 
            END                       AS bucket_id,
            total_profit
    FROM    bucketed
)
SELECT  bucket_id + 1                 AS bucket_number,          -- 1‑10
        COUNT(*)                      AS number_of_customers,
        MIN(total_profit)             AS min_total_profit,
        MAX(total_profit)             AS max_total_profit
FROM    final
GROUP BY bucket_id
ORDER BY bucket_id;