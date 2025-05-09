/*  For every calendar month earlier than 2024‑01,
    pick the product that generated the greatest total profit
    ( Σ(sale_price – product_cost) ) in that month.
    Then report that month’s top‑earning product together with
    its aggregated cost and aggregated profit.                                              */

WITH monthly_product_profit AS (
    SELECT
        /* month in YYYY‑MM form */
        TO_CHAR(TO_TIMESTAMP("created_at" / 1000000), 'YYYY-MM')              AS "month",
        oi."product_id",
        /* aggregate metrics for this product within the month */
        SUM(p."cost")                                                         AS "total_cost",
        SUM(oi."sale_price" - p."cost")                                       AS "total_profit"
    FROM
        THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.ORDER_ITEMS   oi
        JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS p
          ON oi."product_id" = p."id"
    /* keep only order‑items created before 2024‑01‑01 */
    WHERE TO_TIMESTAMP(oi."created_at" / 1000000) < '2024-01-01'
    GROUP BY
        TO_CHAR(TO_TIMESTAMP(oi."created_at" / 1000000), 'YYYY-MM'),
        oi."product_id"
),
ranked AS (
    SELECT
        mp.*,
        ROW_NUMBER() OVER (PARTITION BY "month"
                           ORDER BY "total_profit" DESC, "product_id") AS rn
    FROM monthly_product_profit mp
)
SELECT
    r."month",
    r."product_id",
    p."name"                        AS "product_name",
    r."total_cost",
    r."total_profit"
FROM
    ranked r
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE.PRODUCTS p
      ON r."product_id" = p."id"
WHERE
    r.rn = 1          -- the highest‑profit product of the month
ORDER BY
    r."month";