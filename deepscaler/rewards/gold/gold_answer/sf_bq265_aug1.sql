-- Task: Can you calculate the total sales amount for each user in 2019, where total sale is calculated by multiplying the number of items in each order by the sale price and summing this total across all orders for each user? Limit the results to 100 users.

WITH
  orders AS (
    SELECT
      "order_id",
      "user_id",
      CAST(TO_TIMESTAMP("created_at" / 1000000.0) AS DATE) AS "order_date",
      "num_of_item"
    FROM
      "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"
    WHERE
      TO_TIMESTAMP("created_at" / 1000000.0) BETWEEN TO_TIMESTAMP('2019-01-01') AND TO_TIMESTAMP('2019-12-31')
  ),
  
  order_items AS (
    SELECT
      "order_id",
      ROUND("sale_price", 2) AS "sale_price"
    FROM
      "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"
    WHERE
      TO_TIMESTAMP("created_at" / 1000000.0) BETWEEN TO_TIMESTAMP('2019-01-01') AND TO_TIMESTAMP('2019-12-31')
  ),
  
  orders_with_items AS (
    SELECT
      o."user_id",
      o."order_id",
      o."order_date",
      o."num_of_item",
      oi."sale_price",
      ROUND(o."num_of_item" * oi."sale_price", 2) AS "total_sale"
    FROM
      orders o
    INNER JOIN
      order_items oi
    ON
      o."order_id" = oi."order_id"
  )
  
SELECT
  "user_id",
  SUM("total_sale") AS "total_sales_amount"
FROM
  orders_with_items
GROUP BY
  "user_id"
LIMIT 100;