/*  Top-3 most profitable products per month (Jan-2019 ― Aug-2022)  */
WITH monthly_profit AS (
    SELECT
        DATE_TRUNC('MONTH', TO_TIMESTAMP_NTZ(oi."created_at" / 1e6))  AS "month",
        oi."product_id",
        SUM(oi."sale_price")                              AS "revenue",
        SUM(ii."cost")                                    AS "cogs",
        SUM(oi."sale_price") - SUM(ii."cost")             AS "profit"
    FROM THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."ORDER_ITEMS"      oi
    JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."INVENTORY_ITEMS"  ii
          ON ii."id" = oi."inventory_item_id"
    WHERE oi."status" NOT IN ('Cancelled', 'Returned')
      AND DATE_TRUNC('MONTH', TO_TIMESTAMP_NTZ(oi."created_at" / 1e6))
            BETWEEN '2019-01-01' AND '2022-08-01'
    GROUP BY 1, 2
), ranked AS (
    SELECT
        mp.*,
        ROW_NUMBER() OVER (PARTITION BY mp."month"
                           ORDER BY mp."profit" DESC NULLS LAST) AS "rn"
    FROM monthly_profit mp
)
SELECT
    r."month",
    r."product_id",
    p."name"        AS "product_name",
    r."profit"
FROM ranked r
JOIN THELOOK_ECOMMERCE.THELOOK_ECOMMERCE."PRODUCTS" p
      ON p."id" = r."product_id"
WHERE r."rn" <= 3      -- top-3 per month
ORDER BY r."month" ASC, r."profit" DESC NULLS LAST;