/*────────────────────────────────────────────────────────────────────────
  Recursive monthly inventory simulation (Snowflake dialect)
────────────────────────────────────────────────────────────────────────*/
WITH RECURSIVE
/*————— products that have minimum-inventory rules —————*/
base AS (
    SELECT  "product_id",
            "qty_minimum",
            "qty_purchase"
    FROM    ORACLE_SQL.ORACLE_SQL.PRODUCT_MINIMUMS
),
/*————— aggregated monthly sales from Dec-2018 onwards —————*/
sales AS (
    SELECT  "product_id",
            TO_DATE("mth")                           AS mth,
            SUM("qty")                               AS sales_qty
    FROM    ORACLE_SQL.ORACLE_SQL.MONTHLY_SALES
    WHERE   TO_DATE("mth") >= DATE '2018-12-01'
      AND   "product_id" IN (SELECT "product_id" FROM base)
    GROUP BY "product_id", TO_DATE("mth")
),
/*————— recursive inventory calculation, Dec-2018 → Dec-2019 —————*/
inv AS (     
    /* anchor row : 2018-12 */
    SELECT  b."product_id",
            b."qty_minimum",
            b."qty_purchase",
            DATE '2018-12-01'                        AS mth,
            (b."qty_minimum" + b."qty_purchase")     AS begin_inv,
            COALESCE(s.sales_qty,0)                  AS sales_qty,
            CASE
                WHEN (b."qty_minimum" + b."qty_purchase") - COALESCE(s.sales_qty,0)
                       < b."qty_minimum"
                THEN (b."qty_minimum" + b."qty_purchase") - COALESCE(s.sales_qty,0)
                       + b."qty_purchase"
                ELSE (b."qty_minimum" + b."qty_purchase") - COALESCE(s.sales_qty,0)
            END                                      AS ending_inv
    FROM    base b
    LEFT JOIN sales s
           ON s."product_id" = b."product_id"
          AND s.mth         = DATE '2018-12-01'

    UNION ALL

    /* subsequent months */
    SELECT  i."product_id",
            i."qty_minimum",
            i."qty_purchase",
            DATEADD(month,1,i.mth)                   AS mth,
            i.ending_inv                             AS begin_inv,
            COALESCE(s2.sales_qty,0)                 AS sales_qty,
            CASE
                WHEN i.ending_inv - COALESCE(s2.sales_qty,0) < i."qty_minimum"
                THEN i.ending_inv - COALESCE(s2.sales_qty,0) + i."qty_purchase"
                ELSE i.ending_inv - COALESCE(s2.sales_qty,0)
            END                                      AS ending_inv
    FROM    inv i
    LEFT JOIN sales s2
           ON s2."product_id" = i."product_id"
          AND s2.mth         = DATEADD(month,1,i.mth)
    WHERE   i.mth < DATE '2019-12-01'                -- stop before 2020-01
),
/*————— absolute differences for calendar year 2019 —————*/
diffs AS (
    SELECT  "product_id",
            mth,
            ABS(ending_inv - "qty_minimum")          AS abs_diff,
            ROW_NUMBER() OVER (PARTITION BY "product_id"
                               ORDER BY ABS(ending_inv - "qty_minimum"), mth) AS rn
    FROM    inv
    WHERE   mth BETWEEN DATE '2019-01-01' AND DATE '2019-12-01'
)
/*————— final result —————*/
SELECT  "product_id",
        TO_CHAR(mth,'YYYY-MM')   AS month_2019,
        abs_diff
FROM    diffs
WHERE   rn = 1
ORDER BY "product_id";