WITH valid_order_items AS (
    SELECT
        oi."id"                           AS order_item_id,
        oi."created_at"                  AS created_at_us,
        oi."sale_price"                  AS sale_price,
        ii."cost"                        AS cost,
        oi."product_id"                  AS product_id,
        p."name"                         AS product_name,
        /* convert micro‑seconds epoch to DATE */
        TO_DATE(TO_TIMESTAMP_LTZ(oi."created_at" / 1000000)) AS order_date
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"           o
         ON oi."order_id" = o."order_id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  ii
         ON oi."inventory_item_id" = ii."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"         p
         ON oi."product_id" = p."id"
    WHERE oi."status"   NOT IN ('Cancelled','Returned')
      AND o."status"    NOT IN ('Cancelled','Returned')
      AND TO_DATE(TO_TIMESTAMP_LTZ(oi."created_at" / 1000000))
          BETWEEN '2019-01-01' AND '2022-08-31'
),

monthly_profit AS (
    SELECT
        DATE_TRUNC('month', order_date)                          AS month_start,
        product_id,
        product_name,
        ROUND(SUM(sale_price) - SUM(cost), 4)                    AS profit
    FROM valid_order_items
    GROUP BY month_start, product_id, product_name
),

ranked AS (
    SELECT
        month_start,
        product_name,
        profit,
        ROW_NUMBER() OVER (PARTITION BY month_start
                           ORDER BY profit DESC NULLS LAST,
                                    product_name)                AS rn
    FROM monthly_profit
)

SELECT
    TO_CHAR(month_start, 'YYYY-MM')  AS month,
    product_name,
    profit
FROM ranked
WHERE rn <= 3
ORDER BY month_start,
         profit DESC,
         product_name;