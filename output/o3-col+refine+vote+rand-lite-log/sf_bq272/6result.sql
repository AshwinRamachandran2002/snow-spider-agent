/*  Top-3 most profitable products for every month
    from 2019-01 through 2022-08 (inclusive), 
    ignoring any cancelled or returned order / order-item.  */

WITH monthly_profit AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ(oi."created_at" / 1000000), 'YYYY-MM')          AS "yr_mo",
        p."name"                                                                 AS "product_name",
        SUM(oi."sale_price" - ii."cost")                                         AS "profit"
    FROM   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"      oi
    JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"           o
           ON o."order_id" = oi."order_id"
    JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."INVENTORY_ITEMS"  ii
           ON ii."id" = oi."inventory_item_id"
    JOIN   "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"         p
           ON p."id" = oi."product_id"
    WHERE  oi."status" NOT ILIKE '%cancel%'          -- exclude item-level cancels
      AND  oi."status" NOT ILIKE '%return%'          -- exclude item-level returns
      AND  o."status"  NOT ILIKE '%cancel%'          -- exclude order-level cancels
      AND  o."status"  NOT ILIKE '%return%'          -- exclude order-level returns
      AND  TO_TIMESTAMP_NTZ(oi."created_at" / 1000000) >= '2019-01-01'
      AND  TO_TIMESTAMP_NTZ(oi."created_at" / 1000000) <  '2022-09-01'
    GROUP BY
        "yr_mo",
        p."name"
)

SELECT
    "yr_mo",
    "product_name",
    ROUND("profit", 4)                                                        AS "profit",
    ROW_NUMBER() OVER (PARTITION BY "yr_mo"
                       ORDER BY "profit" DESC NULLS LAST)                     AS "rnk"
FROM monthly_profit
QUALIFY "rnk" <= 3                           -- keep top-3 per month
ORDER BY
    "yr_mo",
    "rnk";