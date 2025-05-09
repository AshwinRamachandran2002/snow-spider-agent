/* Lowest‑profit product(s) for each month of calendar‑year 2020 */
WITH prod_profit AS (
    SELECT
        TO_CHAR(TO_TIMESTAMP_LTZ(oi."created_at" / 1000000), 'YYYYMM')      AS "yyyymm",
        p."name"                                                           AS "product_name",
        (p."retail_price" - p."cost")                                      AS "profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"  oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS"     p
          ON p."id" = oi."product_id"
    WHERE oi."created_at" >= 1577836800000000   -- 2020‑01‑01 00:00:00 µs
      AND oi."created_at" <  1609459200000000   -- 2021‑01‑01 00:00:00 µs
),
monthly_min AS (
    SELECT
        "yyyymm",
        MIN("profit") AS "min_profit"
    FROM prod_profit
    GROUP BY "yyyymm"
)
SELECT
    pp."yyyymm",
    pp."product_name"
FROM prod_profit  pp
JOIN monthly_min  mm
      ON  pp."yyyymm" = mm."yyyymm"
     AND pp."profit"  = mm."min_profit"
ORDER BY
    pp."yyyymm"       /* chronological order */
;