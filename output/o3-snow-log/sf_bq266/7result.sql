/* 1.  Extract all products that were sold (an order_item was created) in 2020,
       reduce to one record per product-month                              */
WITH product_month_sales AS (
    SELECT DISTINCT
           oi."product_id",
           DATE_TRUNC('month', TO_TIMESTAMP_NTZ(oi."created_at"/1000000))  AS "month_start"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS" oi
    WHERE  oi."created_at" IS NOT NULL
      AND  DATE_PART('year', TO_TIMESTAMP_NTZ(oi."created_at"/1000000)) = 2020
),

/* 2.  Get each product’s profit (retail_price – cost)                    */
product_profit AS (
    SELECT  p."id"                              AS "product_id",
            p."name"                            AS "product_name",
            (p."retail_price" - p."cost")       AS "profit"
    FROM    THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
),

/* 3.  Combine the two sets and rank products by profit (ascending)       */
ranked_products AS (
    SELECT  pms."month_start",
            pp."product_name",
            pp."profit",
            RANK() OVER (PARTITION BY pms."month_start"
                         ORDER BY pp."profit" ASC) AS rnk
    FROM    product_month_sales  pms
    JOIN    product_profit       pp
           ON pp."product_id" = pms."product_id"
)

/* 4.  Pick the lowest-profit product(s) for each month and list them
       in chronological order                                             */
SELECT
       TO_CHAR("month_start", 'YYYY-MM') AS "month",
       "product_name"
FROM   ranked_products
WHERE  rnk = 1
ORDER  BY "month_start";