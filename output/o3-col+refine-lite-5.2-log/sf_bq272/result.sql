/*  Top‑3 most profitable products per month (Jan‑2019 → Aug‑2022)
    – Profit = Σ(sale_price) − Σ(cost)
    – Excludes any order or item that is Cancelled or Returned            */

WITH eligible_items AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ(oi."created_at" / 1000000), 'YYYY-MM')   AS "month",
        oi."product_id",
        p."name"                                                         AS "product_name",
        oi."sale_price",
        ii."cost"
    FROM   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"     oi
    JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"          o
           ON oi."order_id" = o."order_id"
    JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."INVENTORY_ITEMS" ii
           ON oi."inventory_item_id" = ii."id"
    JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"        p
           ON oi."product_id" = p."id"
    WHERE  o."status"  NOT IN ('Cancelled','Returned')      -- exclude unwanted orders
      AND  oi."status" NOT IN ('Cancelled','Returned')      -- exclude unwanted items
      AND  TO_DATE(TO_TIMESTAMP_NTZ(oi."created_at" / 1000000))
           BETWEEN '2019-01-01' AND '2022-08-31'            -- required date window
),
profit_per_product AS (
    SELECT
        "month",
        "product_id",
        "product_name",
        SUM("sale_price")                AS "total_sales",
        SUM("cost")                      AS "total_cost",
        SUM("sale_price") - SUM("cost")  AS "profit"
    FROM   eligible_items
    GROUP BY "month","product_id","product_name"
),
ranked AS (
    SELECT
        "month",
        "product_name",
        "profit",
        RANK() OVER (PARTITION BY "month" ORDER BY "profit" DESC) AS "rk"
    FROM   profit_per_product
)
SELECT
    "month",
    "product_name",
    "profit"
FROM   ranked
WHERE  "rk" <= 3
ORDER BY
    "month",
    "rk",
    "product_name";