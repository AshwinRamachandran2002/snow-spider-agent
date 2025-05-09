SELECT
    ranked."month",
    ranked."product_name",
    ranked."profit"
FROM (
    SELECT
        /* month key as YYYY-MM */
        TO_CHAR(
            DATE_TRUNC(
                'MONTH',
                TO_TIMESTAMP(oi."created_at" / 1000000)
            ),
            'YYYY-MM'
        )                                          AS "month",
        p."name"                                   AS "product_name",
        SUM(oi."sale_price") - SUM(ii."cost")      AS "profit",
        ROW_NUMBER() OVER (
            PARTITION BY TO_CHAR(
                            DATE_TRUNC(
                                'MONTH',
                                TO_TIMESTAMP(oi."created_at" / 1000000)
                            ),
                            'YYYY-MM'
                        )
            ORDER BY SUM(oi."sale_price") - SUM(ii."cost") DESC NULLS LAST
        )                                          AS "rk"
    FROM   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      oi
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  ii
           ON oi."inventory_item_id" = ii."id"
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"         p
           ON oi."product_id" = p."id"
    JOIN   THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDERS"           o
           ON oi."order_id" = o."order_id"
    WHERE  oi."status"      NOT ILIKE '%cancel%'      -- exclude cancelled items
      AND  o."status"       NOT ILIKE '%cancel%'      -- exclude cancelled orders
      AND  oi."returned_at" IS NULL                   -- exclude returned items
      AND  DATE_TRUNC(
              'MONTH',
              TO_TIMESTAMP(oi."created_at" / 1000000)
           ) BETWEEN '2019-01-01'::DATE
               AND     '2022-08-31'::DATE
    GROUP BY
        TO_CHAR(
            DATE_TRUNC(
                'MONTH',
                TO_TIMESTAMP(oi."created_at" / 1000000)
            ),
            'YYYY-MM'
        ),
        p."name"
) ranked
WHERE ranked."rk" <= 3
ORDER BY ranked."month", ranked."rk";