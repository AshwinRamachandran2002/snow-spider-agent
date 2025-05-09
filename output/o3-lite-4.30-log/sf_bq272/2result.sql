WITH valid_items AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP_NTZ(o."created_at" / 1000000), 'YYYY-MM') AS "year_month",
        p."name"                                                      AS "product_name",
        o."sale_price",
        i."cost"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"     o
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS" i
         ON o."inventory_item_id" = i."id"
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"        p
         ON o."product_id" = p."id"
    WHERE o."status" NOT ILIKE '%cancel%'          -- exclude cancelled
      AND o."status" NOT ILIKE '%return%'          -- exclude returned status
      AND o."returned_at" IS NULL                  -- exclude rows with a return timestamp
      AND TO_TIMESTAMP_NTZ(o."created_at" / 1000000) >= '2019-01-01'
      AND TO_TIMESTAMP_NTZ(o."created_at" / 1000000) <  '2022-09-01'   -- through Aug‑2022
), monthly_profit AS (
    SELECT
        "year_month",
        "product_name",
        SUM("sale_price") - SUM("cost") AS "profit"
    FROM valid_items
    GROUP BY "year_month", "product_name"
), ranked AS (
    SELECT
        "year_month",
        "product_name",
        "profit",
        RANK() OVER (
            PARTITION BY "year_month"
            ORDER BY "profit" DESC, "product_name" ASC
        ) AS "rk"
    FROM monthly_profit
)
SELECT
    "year_month",
    "product_name",
    ROUND("profit", 4) AS "profit",
    "rk"               AS "rank_in_month"
FROM ranked
WHERE "rk" <= 3
ORDER BY "year_month", "rk";