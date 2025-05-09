/* -------------------------------------------------------------
   Recursive monthly inventory model
   -------------------------------------------------------------
   • Start month              : 2018-12-01
   • Horizon                  : through 2019-12-01
   • Restock rule (per month) : if (ending  <  qty_minimum)
                                add  qty_purchase
   • Goal                     : for each product, pick the
                                2019 month whose ending stock
                                is closest (absolute distance)
                                to the minimum required level
   -------------------------------------------------------------*/
WITH RECURSIVE
/* 1. Minimum / purchase parameters for every product */
product_min AS (
    SELECT
        "product_id",
        "qty_minimum",
        "qty_purchase"
    FROM "ORACLE_SQL"."ORACLE_SQL"."PRODUCT_MINIMUMS"
),

/* 2. Monthly sales totals (Dec-2018 … Dec-2019) */
sales AS (
    SELECT
        TO_DATE("mth")                 AS mth,
        "product_id",
        SUM("qty")                     AS sales_qty
    FROM "ORACLE_SQL"."ORACLE_SQL"."MONTHLY_SALES"
    WHERE TO_DATE("mth") BETWEEN TO_DATE('2018-12-01')
                             AND     TO_DATE('2019-12-31')
    GROUP BY
        TO_DATE("mth"),
        "product_id"
),

/* 3. Anchor row : December-2018 (use purchase qty as opening stock) */
inv_anchor AS (
    SELECT
        pm."product_id",
        TO_DATE('2018-12-01')          AS mth,
        pm."qty_minimum",
        pm."qty_purchase",
        COALESCE(s.sales_qty ,0)       AS sales_qty,
        /* ending inventory for December-2018 */
        CASE
            WHEN pm."qty_purchase" - COALESCE(s.sales_qty,0) < pm."qty_minimum"
                 THEN pm."qty_purchase" - COALESCE(s.sales_qty,0) + pm."qty_purchase"
            ELSE pm."qty_purchase" - COALESCE(s.sales_qty,0)
        END                            AS end_inv
    FROM product_min pm
    LEFT JOIN sales s
           ON  s."product_id" = pm."product_id"
           AND s.mth          = TO_DATE('2018-12-01')
),

/* 4. Recursive part : propagate month by month until 2019-12-01 */
inv_recursive AS (
    /* ---- anchor ---- */
    SELECT * FROM inv_anchor

    UNION ALL

    /* ---- next month ---- */
    SELECT
        ir."product_id",
        DATEADD(month,1,ir.mth)                        AS mth,
        ir."qty_minimum",
        ir."qty_purchase",
        COALESCE(s.sales_qty,0)                        AS sales_qty,
        CASE
            WHEN ir.end_inv - COALESCE(s.sales_qty,0) < ir."qty_minimum"
                 THEN ir.end_inv - COALESCE(s.sales_qty,0) + ir."qty_purchase"
            ELSE ir.end_inv - COALESCE(s.sales_qty,0)
        END                                            AS end_inv
    FROM inv_recursive  ir
    LEFT JOIN sales     s
           ON  s."product_id" = ir."product_id"
           AND s.mth          = DATEADD(month,1,ir.mth)
    WHERE ir.mth < TO_DATE('2019-12-01')               -- stop after Dec-2019
)

/* 5. Pick, for each product, the 2019 month with the
      smallest |ending − minimum| difference              */
SELECT
    "product_id",
    TO_CHAR(mth,'YYYY-MM')                 AS month,
    ABS(end_inv - "qty_minimum")           AS abs_difference
FROM (
    SELECT
        "product_id",
        mth,
        end_inv,
        "qty_minimum",
        ROW_NUMBER() OVER (PARTITION BY "product_id"
                           ORDER BY ABS(end_inv - "qty_minimum") ,
                                    mth)  AS rn
    FROM inv_recursive
    WHERE mth BETWEEN TO_DATE('2019-01-01')
                 AND     TO_DATE('2019-12-31')
)
WHERE rn = 1
ORDER BY "product_id";