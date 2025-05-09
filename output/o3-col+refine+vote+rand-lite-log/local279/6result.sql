WITH RECURSIVE
/* 1. products that have a minimum-stock rule                                       */
prod AS (
    SELECT "product_id",
           "qty_minimum",
           "qty_purchase"
    FROM   "product_minimums"
),

/* 2. on-hand stock as of 31-Dec-2018 (starting level for the simulation)          */
start_inv AS (
    SELECT i."product_id",
           SUM(i."qty") AS start_qty
    FROM   "inventory"  i
    JOIN   "purchases"  pu ON pu."id" = i."purchase_id"
    WHERE  pu."purchased" <= '2018-12-31'
      AND  i."product_id" IN (SELECT "product_id" FROM prod)
    GROUP  BY i."product_id"
),

/* 3. list the 12 months of 2019                                                    */
months(mth) AS (
    VALUES ('2019-01-01')
    UNION ALL
    SELECT DATE(mth,'+1 month') FROM months WHERE mth < '2019-12-01'
),

/* 4. monthly sales in 2019 for the same products                                   */
sales AS (
    SELECT "product_id",
           DATE("mth")           AS mth,
           SUM("qty")            AS sales_qty
    FROM   "monthly_sales"
    WHERE  "mth" BETWEEN '2019-01-01' AND '2019-12-31'
      AND  "product_id" IN (SELECT "product_id" FROM prod)
    GROUP  BY "product_id", DATE("mth")
),

/* 5. recursive inventory calculation, month by month                               */
inv AS (
    /* ----- January 2019 (anchor row) ------------------------------------------- */
    SELECT p."product_id",
           '2019-01-01'                AS mth,
           p."qty_minimum",
           p."qty_purchase",
           COALESCE(s.sales_qty,0)     AS sales_qty,
           si.start_qty                AS prev_inv,
           CASE
               WHEN (si.start_qty - COALESCE(s.sales_qty,0)) < p."qty_minimum"
                    THEN (si.start_qty - COALESCE(s.sales_qty,0)) + p."qty_purchase"
               ELSE (si.start_qty - COALESCE(s.sales_qty,0))
           END                         AS end_inv
    FROM   prod p
    JOIN   start_inv  si ON si."product_id" = p."product_id"
    LEFT   JOIN sales s   ON s."product_id" = p."product_id"
                         AND s.mth          = '2019-01-01'

    UNION ALL
    /* ----- the following months ------------------------------------------------- */
    SELECT i."product_id",
           DATE(i.mth,'+1 month')                     AS mth,
           i."qty_minimum",
           i."qty_purchase",
           COALESCE(s.sales_qty,0)                   AS sales_qty,
           i.end_inv                                 AS prev_inv,
           CASE
               WHEN (i.end_inv - COALESCE(s.sales_qty,0)) < i."qty_minimum"
                    THEN (i.end_inv - COALESCE(s.sales_qty,0)) + i."qty_purchase"
               ELSE (i.end_inv - COALESCE(s.sales_qty,0))
           END                                       AS end_inv
    FROM   inv  i
    JOIN   months m        ON m.mth = DATE(i.mth,'+1 month')
    LEFT   JOIN sales  s   ON s."product_id" = i."product_id"
                          AND s.mth          = DATE(i.mth,'+1 month')
    WHERE  i.mth < '2019-12-01'   /* stop after December 2019 has been produced */
)

/* 6. pick the 2019 month whose ending stock sits closest to the minimum           */
SELECT product_id,
       mth,
       ABS(end_inv - qty_minimum) AS abs_difference
FROM (
    SELECT product_id,
           mth,
           qty_minimum,
           end_inv,
           ROW_NUMBER() OVER (PARTITION BY product_id
                              ORDER BY ABS(end_inv - qty_minimum)) AS rn
    FROM   inv
)
WHERE rn = 1
ORDER BY product_id;