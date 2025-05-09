/* -----------------------------------------------------------
   For every product that has a replenishment rule, find the
   2019-month whose ENDING inventory is closest to its minimum
   level – using the specified restocking logic.
----------------------------------------------------------- */
WITH
/* 1. Replenishment rules */
rules AS (
    SELECT  "product_id",
            "qty_minimum",
            "qty_purchase"
    FROM ORACLE_SQL.ORACLE_SQL."PRODUCT_MINIMUMS"
),

/* 2. Ending inventory for December-2018 (starting point) */
start_inv AS (
    SELECT
        r."product_id",
        COALESCE(b."qty",0) - COALESCE(s."qty",0) AS end_inventory
    FROM rules r
    LEFT JOIN ORACLE_SQL.ORACLE_SQL."MONTHLY_BUDGET"  b
           ON b."product_id" = r."product_id"
          AND b."mth"        = '2018-12-01'
    LEFT JOIN ORACLE_SQL.ORACLE_SQL."MONTHLY_SALES"   s
           ON s."product_id" = r."product_id"
          AND s."mth"        = '2018-12-01'
),

/* 3. The 12 calendar months of 2019 */
months AS (
    SELECT 
        TO_CHAR(DATEADD(month, seq4(), '2019-01-01'::DATE), 'YYYY-MM-01') AS mth,
        seq4() AS m_idx
    FROM TABLE(GENERATOR(ROWCOUNT => 12))
),

/* 4. 2019 sales (missing rows handled later as zero) */
sales19 AS (
    SELECT  "product_id",
            "mth",
            "qty"
    FROM ORACLE_SQL.ORACLE_SQL."MONTHLY_SALES"
    WHERE  "mth" BETWEEN '2019-01-01' AND '2019-12-01'
),

/* 5. Recursive monthly inventory calculation */
inv_recursive AS (
    /* ----- January-2019 (anchor) ----- */
    SELECT
        si."product_id",
        m.mth,
        m.m_idx,
        si.end_inventory                              AS start_inv,
        COALESCE(s."qty",0)                           AS sales_qty,
        CASE WHEN si.end_inventory - COALESCE(s."qty",0) < r."qty_minimum"
                 THEN r."qty_purchase" ELSE 0 END     AS restock_qty,
        (si.end_inventory - COALESCE(s."qty",0))
        + CASE WHEN si.end_inventory - COALESCE(s."qty",0) < r."qty_minimum"
                 THEN r."qty_purchase" ELSE 0 END     AS end_inv,
        r."qty_minimum"
    FROM start_inv si
    JOIN rules  r   ON r."product_id" = si."product_id"
    JOIN months m   ON m.m_idx = 0                      -- 2019-01
    LEFT JOIN sales19 s
           ON s."product_id" = si."product_id"
          AND s."mth"        = m.mth

    UNION ALL

    /* ----- February-2019 … December-2019 ----- */
    SELECT
        prev."product_id",
        m.mth,
        m.m_idx,
        prev.end_inv                                  AS start_inv,
        COALESCE(s."qty",0)                           AS sales_qty,
        CASE WHEN prev.end_inv - COALESCE(s."qty",0) < r."qty_minimum"
                 THEN r."qty_purchase" ELSE 0 END     AS restock_qty,
        (prev.end_inv - COALESCE(s."qty",0))
        + CASE WHEN prev.end_inv - COALESCE(s."qty",0) < r."qty_minimum"
                 THEN r."qty_purchase" ELSE 0 END     AS end_inv,
        r."qty_minimum"
    FROM inv_recursive prev
    JOIN months m         ON m.m_idx = prev.m_idx + 1   -- next month
    JOIN rules  r         ON r."product_id" = prev."product_id"
    LEFT JOIN sales19 s
           ON s."product_id" = prev."product_id"
          AND s."mth"        = m.mth
),

/* 6. Rank months by closeness to the minimum */
ranked AS (
    SELECT
        "product_id",
        mth,
        ABS(end_inv - "qty_minimum") AS diff,
        ROW_NUMBER() OVER (PARTITION BY "product_id"
                           ORDER BY ABS(end_inv - "qty_minimum")) AS rn
    FROM inv_recursive
)

/* 7. Final result */
SELECT
    "product_id",
    mth  AS month_with_smallest_gap,
    diff AS absolute_difference
FROM ranked
WHERE rn = 1
ORDER BY "product_id";