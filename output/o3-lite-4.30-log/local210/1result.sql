WITH feb AS (
    SELECT s.hub_id,
           COUNT(*) AS cnt_feb
    FROM orders o
    JOIN stores s ON s.store_id = o.store_id
    WHERE o.order_status = 'FINISHED'
      AND o.order_created_month = 2
      AND o.order_created_year = 2021
    GROUP BY s.hub_id
),
mar AS (
    SELECT s.hub_id,
           COUNT(*) AS cnt_mar
    FROM orders o
    JOIN stores s ON s.store_id = o.store_id
    WHERE o.order_status = 'FINISHED'
      AND o.order_created_month = 3
      AND o.order_created_year = 2021
    GROUP BY s.hub_id
)
SELECT h.hub_name,
       ROUND((cnt_mar - cnt_feb) * 100.0 / cnt_feb, 4) AS percent_increase
FROM feb
JOIN mar ON mar.hub_id = feb.hub_id
JOIN hubs h ON h.hub_id = feb.hub_id
WHERE (cnt_mar - cnt_feb) * 1.0 / cnt_feb > 0.20;