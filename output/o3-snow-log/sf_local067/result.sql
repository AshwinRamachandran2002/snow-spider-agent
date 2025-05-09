WITH italian_customers AS (
    SELECT  c."cust_id"
    FROM    COMPLEX_ORACLE.COMPLEX_ORACLE.CUSTOMERS  c
    JOIN    COMPLEX_ORACLE.COMPLEX_ORACLE.COUNTRIES  cn
           ON c."country_id" = cn."country_id"
    WHERE   cn."country_name" = 'Italy'
), 

dec21_sales AS (
    SELECT  s."cust_id",
            s."prod_id",
            s."channel_id",
            s."promo_id",
            s."time_id",
            s."quantity_sold",
            s."amount_sold"
    FROM    COMPLEX_ORACLE.COMPLEX_ORACLE.SALES  s
    WHERE   s."time_id" BETWEEN '2021-12-01' AND '2021-12-31'
), 

sale_profits AS (
    SELECT  d."cust_id",
            ( d."amount_sold"
              - d."quantity_sold"
                * COALESCE(cst."unit_cost", 0)
            )                          AS "profit"
    FROM    dec21_sales                      d
    JOIN    italian_customers                ic  ON d."cust_id" = ic."cust_id"
    LEFT JOIN COMPLEX_ORACLE.COMPLEX_ORACLE.COSTS cst
           ON  d."prod_id"   = cst."prod_id"
           AND d."time_id"   = cst."time_id"
           AND d."channel_id"= cst."channel_id"
           AND d."promo_id"  = cst."promo_id"
), 

cust_dec_profits AS (
    SELECT  "cust_id",
            SUM("profit")  AS "total_profit"
    FROM    sale_profits
    GROUP BY "cust_id"
), 

tiered_profits AS (
    SELECT  "cust_id",
            "total_profit",
            NTILE(10) OVER (ORDER BY "total_profit" DESC) AS "tier"
    FROM    cust_dec_profits
)

SELECT  "tier",
        MAX("total_profit") AS "highest_profit",
        MIN("total_profit") AS "lowest_profit"
FROM    tiered_profits
GROUP BY "tier"
ORDER BY "tier";