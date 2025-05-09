WITH italian_customers AS (
    SELECT cust_id
    FROM   customers
    WHERE  country_id IN (
        SELECT country_id
        FROM   countries
        WHERE  country_name = 'Italy'
    )
),
cust_dec_profits AS (
    SELECT  s.cust_id,
            SUM(s.amount_sold - s.quantity_sold * c.unit_cost) AS total_profit_dec2021
    FROM    sales  AS s
    JOIN    costs  AS c
           ON  s.prod_id = c.prod_id
           AND s.time_id = c.time_id
    WHERE   s.cust_id IN (SELECT cust_id FROM italian_customers)
      AND   s.time_id BETWEEN '2021-12-01' AND '2021-12-31'
    GROUP BY s.cust_id
),
profit_deciles AS (
    SELECT  cust_id,
            total_profit_dec2021,
            NTILE(10) OVER (ORDER BY total_profit_dec2021 DESC) AS profit_decile
    FROM    cust_dec_profits
)
SELECT  profit_decile,
        MIN(total_profit_dec2021) AS lowest_profit,
        MAX(total_profit_dec2021) AS highest_profit
FROM    profit_deciles
GROUP BY profit_decile
ORDER BY profit_decile;