WITH monthly_product_profit AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ(oi."created_at" / 1e6), 'YYYY-MM') AS "year_month",
        p."name"                                                    AS "product_name",
        SUM(oi."sale_price") - SUM(ii."cost")                       AS "profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  ii
          ON oi."inventory_item_id" = ii."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"         p
          ON oi."product_id" = p."id"
    WHERE oi."status" NOT ILIKE '%cancel%'      -- exclude cancelled
      AND oi."status" NOT ILIKE '%return%'      -- exclude returned
      AND TO_CHAR(TO_TIMESTAMP_NTZ(oi."created_at" / 1e6), 'YYYY-MM')
            BETWEEN '2019-01' AND '2022-08'
    GROUP BY
        1, 2
),
ranked_profit AS (
    SELECT
        "year_month",
        "product_name",
        "profit",
        ROW_NUMBER() OVER (
            PARTITION BY "year_month"
            ORDER BY "profit" DESC
        ) AS "rnk"
    FROM monthly_product_profit
)
SELECT
    "year_month",
    "product_name",
    ROUND("profit", 4) AS "profit"
FROM ranked_profit
WHERE "rnk" <= 3
ORDER BY
    "year_month",
    "rnk";