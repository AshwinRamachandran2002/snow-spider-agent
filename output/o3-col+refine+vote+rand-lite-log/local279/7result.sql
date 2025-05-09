WITH RECURSIVE
/* 1. Calendar for every month of 2019 */
cal(mth) AS (
    VALUES('2019-01')
    UNION ALL
    SELECT strftime('%Y-%m',
                    date(mth||'-01','start of month','+1 month'))
    FROM   cal
    WHERE  mth < '2019-12'
),

/* 2. Closing stock as at 31-Dec-2018                            */
start_inv AS (
    SELECT i."product_id",
           SUM(i."qty") AS "qty"
    FROM   "inventory"  i
    JOIN   "purchases"  p  ON p."id" = i."purchase_id"
    WHERE  p."purchased" <= '2018-12-31'
    GROUP  BY i."product_id"
),

/* 3. 2019 monthly sales quantities                             */
sales AS (
    SELECT "product_id",
           substr("mth",1,7) AS "mth",
           SUM("qty")        AS "sales_qty"
    FROM   "monthly_sales"
    WHERE  "mth" LIKE '2019-%'
    GROUP  BY 1,2
),

/* 4. Minimum / purchase-to levels                              */
minlvl AS (
    SELECT * FROM "product_minimums"
),

/* 5. List of all products we must simulate                     */
products AS (
    SELECT "product_id" FROM minlvl
    UNION
    SELECT "product_id" FROM start_inv
    UNION
    SELECT "product_id" FROM sales
),

/* 6. Recursive month-by-month inventory adjustment for 2019    */
rec AS (
    /* first month (Jan-2019) */
    SELECT p."product_id"          AS prod,
           '2019-01'               AS mth,
           COALESCE(si.qty,0)      AS beg_qty,
           COALESCE(s1.sales_qty,0)                  AS sales_qty,
           COALESCE(si.qty,0) - COALESCE(s1.sales_qty,0) AS end_qty
    FROM   products  p
    LEFT  JOIN start_inv si ON si."product_id" = p."product_id"
    LEFT  JOIN sales     s1 ON s1."product_id" = p."product_id"
                            AND s1.mth = '2019-01'

    UNION ALL

    /* subsequent months */
    SELECT r.prod,
           nxt.mth,
           CASE WHEN r.end_qty < ml.qty_minimum
                THEN r.end_qty + ml.qty_purchase   /* restock */
                ELSE r.end_qty
           END                        AS beg_qty,
           COALESCE(s2.sales_qty,0)   AS sales_qty,
           CASE WHEN r.end_qty < ml.qty_minimum
                THEN r.end_qty + ml.qty_purchase
                ELSE r.end_qty
           END - COALESCE(s2.sales_qty,0)           AS end_qty
    FROM   rec   r
    JOIN   cal   cur ON cur.mth = r.mth
    JOIN   cal   nxt ON nxt.mth = strftime('%Y-%m',
                                          date(cur.mth||'-01','+1 month'))
    JOIN   minlvl ml  ON ml."product_id" = r.prod
    LEFT  JOIN sales  s2 ON s2."product_id" = r.prod
                         AND s2.mth = nxt.mth
    WHERE  nxt.mth <= '2019-12'
),

/* 7. Absolute deviation from minimum level                     */
diff AS (
    SELECT r.prod AS product_id,
           r.mth,
           ABS(r.end_qty - ml.qty_minimum) AS abs_diff
    FROM   rec r
    JOIN   minlvl ml ON ml."product_id" = r.prod
),

/* 8. Best (smallest) deviation per product                     */
best AS (
    SELECT product_id,
           MIN(abs_diff) AS best_diff
    FROM   diff
    GROUP  BY product_id
)

/* 9. Final answer                                              */
SELECT d.product_id,
       d.mth,
       d.abs_diff
FROM   diff d
JOIN   best b
  ON   b.product_id = d.product_id
 AND   b.best_diff  = d.abs_diff
ORDER  BY d.product_id,
          d.mth;