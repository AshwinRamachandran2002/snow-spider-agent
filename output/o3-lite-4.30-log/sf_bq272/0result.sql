SELECT
    ranked.sale_month,
    ranked.product_name,
    ROUND(ranked.profit, 4) AS profit
FROM (
    SELECT
        DATE_TRUNC(
            'month',
            TO_TIMESTAMP_NTZ(oi."created_at" / 1e6)
        )                                   AS sale_month,
        p."name"                            AS product_name,
        SUM(oi."sale_price") - SUM(ii."cost") AS profit,
        ROW_NUMBER() OVER (
            PARTITION BY DATE_TRUNC(
                'month',
                TO_TIMESTAMP_NTZ(oi."created_at" / 1e6)
            )
            ORDER BY SUM(oi."sale_price") - SUM(ii."cost") DESC
        )                                   AS rn
    FROM
        "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDER_ITEMS"     oi
        JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."ORDERS"     o
            ON o."order_id" = oi."order_id"
        JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."INVENTORY_ITEMS" ii
            ON ii."id" = oi."inventory_item_id"
        JOIN "THELOOK_ECOMMERCE"."THELOOK_ECOMMERCE"."PRODUCTS"   p
            ON p."id" = oi."product_id"
    WHERE
        oi."status" NOT IN ('Cancelled', 'Returned')
        AND o."status"  NOT IN ('Cancelled', 'Returned')
        AND DATE_TRUNC(
                'month',
                TO_TIMESTAMP_NTZ(oi."created_at" / 1e6)
            ) BETWEEN '2019-01-01' AND '2022-08-01'
    GROUP BY
        sale_month,
        product_name
) ranked
WHERE
    ranked.rn <= 3
ORDER BY
    ranked.sale_month,
    ranked.profit DESC NULLS LAST,
    ranked.product_name;