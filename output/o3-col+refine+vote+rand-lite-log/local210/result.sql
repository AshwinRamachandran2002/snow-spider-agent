WITH feb AS (
    SELECT  s."hub_id",
            COUNT(*) AS cnt_feb
    FROM    "orders"  o
    JOIN    "stores"  s ON s."store_id" = o."store_id"
    WHERE   o."order_status"       = 'FINISHED'
      AND   o."order_created_month" = 2      -- February
    GROUP BY s."hub_id"
),
mar AS (
    SELECT  s."hub_id",
            COUNT(*) AS cnt_mar
    FROM    "orders"  o
    JOIN    "stores"  s ON s."store_id" = o."store_id"
    WHERE   o."order_status"       = 'FINISHED'
      AND   o."order_created_month" = 3      -- March
    GROUP BY s."hub_id"
)
SELECT  h."hub_id",
        h."hub_name",
        feb.cnt_feb,
        mar.cnt_mar,
        ROUND( (mar.cnt_mar - feb.cnt_feb) * 100.0 / feb.cnt_feb , 2) AS pct_change
FROM    feb
JOIN    mar ON mar."hub_id" = feb."hub_id"
JOIN    "hubs" h ON h."hub_id" = feb."hub_id"
WHERE   mar.cnt_mar > feb.cnt_feb                     -- growth
  AND   (mar.cnt_mar - feb.cnt_feb) * 1.0 / feb.cnt_feb > 0.20   -- > 20 %
ORDER BY pct_change DESC;