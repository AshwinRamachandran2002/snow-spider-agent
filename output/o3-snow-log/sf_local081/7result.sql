/*---------------------------------------------------------------
  1) Identify all orders placed during calendar year 1998
  2) Calculate the total (undiscounted) spend per customer
  3) Map every customer-total to a spending group using the
     CUSTOMERGROUPTHRESHOLD table
  4) Count customers in each group and work out the percentage
----------------------------------------------------------------*/
WITH orders_1998 AS (
    SELECT  "orderid",
            "customerid"
    FROM    NORTHWIND.NORTHWIND.ORDERS
    WHERE   YEAR(TO_DATE("orderdate",'YYYY-MM-DD')) = 1998
), 
customer_spend AS (
    SELECT  o."customerid",
            SUM(od."unitprice" * od."quantity") AS total_spent
    FROM    orders_1998               o
    JOIN    NORTHWIND.NORTHWIND.ORDER_DETAILS od
           ON o."orderid" = od."orderid"
    GROUP BY o."customerid"
), 
spending_group AS (
    SELECT  cs."customerid",
            cs.total_spent,
            cgt."groupname"
    FROM    customer_spend                              cs
    LEFT JOIN NORTHWIND.NORTHWIND.CUSTOMERGROUPTHRESHOLD cgt
           ON cs.total_spent >= cgt."rangebottom"
          AND cs.total_spent <= cgt."rangetop"
)
SELECT  sg."groupname"                                   AS spending_group,
        COUNT(DISTINCT sg."customerid")                  AS customer_count,
        ROUND(
               COUNT(DISTINCT sg."customerid") * 100.0
               / (SELECT COUNT(*) FROM customer_spend)
             , 2)                                        AS pct_of_total_customers
FROM    spending_group sg
GROUP BY sg."groupname"
ORDER BY customer_count DESC NULLS LAST;