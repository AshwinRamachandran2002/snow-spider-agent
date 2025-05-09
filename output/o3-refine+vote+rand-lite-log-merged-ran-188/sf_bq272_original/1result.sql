WITH ordered_items AS (      -- every qualifying order‑item, stamped to the month it was sold
    SELECT
        oi."id"                               AS order_item_id ,
        oi."product_id" ,
        oi."sale_price" ,
        inv."cost" ,
        DATE_TRUNC( 'month'
                  , TO_TIMESTAMP( oi."created_at" / 1000000 )
                  )                           AS order_month
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"        oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"             o
             ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"    inv
             ON oi."inventory_item_id" = inv."id"
    WHERE oi."status" NOT IN ( 'Cancelled' , 'Returned' )         -- item itself not cancelled / returned
      AND ( o."status" IS NULL OR o."status" <> 'Cancelled' )     -- whole order not cancelled
      AND o."returned_at" IS NULL                                 -- order not returned
      AND TO_TIMESTAMP( oi."created_at" / 1000000 ) >= '2019-01-01'
      AND TO_TIMESTAMP( oi."created_at" / 1000000 ) <  '2022-09-01'
),

profit_by_product_month AS (  -- profit per product per month
    SELECT
        order_month ,
        "product_id" ,
        SUM( "sale_price" ) - SUM( "cost" )  AS profit
    FROM ordered_items
    GROUP BY order_month , "product_id"
),

ranked_products AS (         -- rank products by profit inside each month
    SELECT
        pbpm.order_month ,
        p."name"                           AS product_name ,
        pbpm.profit ,
        ROW_NUMBER() OVER ( PARTITION BY pbpm.order_month
                            ORDER BY pbpm.profit DESC , p."name" ) AS rn
    FROM profit_by_product_month pbpm
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"  p
            ON pbpm."product_id" = p."id"
)

SELECT
    TO_CHAR( order_month , 'YYYY-MM' ) AS month ,
    product_name ,
    ROUND( profit , 4 )                AS profit
FROM ranked_products
WHERE rn <= 3                                          -- top‑3 for each month
ORDER BY order_month , rn;