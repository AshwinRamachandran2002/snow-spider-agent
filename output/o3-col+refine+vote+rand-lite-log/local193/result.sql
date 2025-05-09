SELECT
    ROUND(AVG(100.0 * COALESCE(l7."ltv_7d", 0)  / ltv."ltv_total"), 4) AS "avg_pct_7d",
    ROUND(AVG(100.0 * COALESCE(l30."ltv_30d", 0) / ltv."ltv_total"), 4) AS "avg_pct_30d",
    ROUND(AVG(ltv."ltv_total"), 4)                                      AS "avg_ltv"
FROM   (
        /* lifetime value per customer */
        SELECT   "customer_id",
                 SUM("amount") AS "ltv_total"
        FROM     "payment"
        GROUP BY "customer_id"
       ) AS ltv
LEFT JOIN
       (
        /* sales in the first 7×24h after first purchase */
        SELECT   p."customer_id",
                 SUM(p."amount") AS "ltv_7d"
        FROM     "payment" AS p
        JOIN     (SELECT "customer_id",
                         MIN("payment_date") AS "t0"
                  FROM   "payment"
                  GROUP  BY "customer_id") AS c
               ON p."customer_id" = c."customer_id"
        WHERE    (strftime('%s', p."payment_date") - strftime('%s', c."t0")) <= 7*24*60*60
        GROUP BY p."customer_id"
       ) AS l7
       ON ltv."customer_id" = l7."customer_id"
LEFT JOIN
       (
        /* sales in the first 30×24h after first purchase */
        SELECT   p."customer_id",
                 SUM(p."amount") AS "ltv_30d"
        FROM     "payment" AS p
        JOIN     (SELECT "customer_id",
                         MIN("payment_date") AS "t0"
                  FROM   "payment"
                  GROUP  BY "customer_id") AS c
               ON p."customer_id" = c."customer_id"
        WHERE    (strftime('%s', p."payment_date") - strftime('%s', c."t0")) <= 30*24*60*60
        GROUP BY p."customer_id"
       ) AS l30
       ON ltv."customer_id" = l30."customer_id"
WHERE  ltv."ltv_total" > 0;