SELECT
    h.hub_name,
    ROUND((fm.mar_cnt - fm.feb_cnt) * 1.0 / fm.feb_cnt, 4) AS percent_increase
FROM (
    SELECT
        s.hub_id,
        SUM(CASE WHEN o.order_created_month = 2 THEN 1 ELSE 0 END) AS feb_cnt,
        SUM(CASE WHEN o.order_created_month = 3 THEN 1 ELSE 0 END) AS mar_cnt
    FROM orders o
    JOIN stores s ON s.store_id = o.store_id
    WHERE o.order_status = 'FINISHED'
      AND o.order_created_month IN (2, 3)
    GROUP BY s.hub_id
) fm
JOIN hubs h ON h.hub_id = fm.hub_id
WHERE fm.feb_cnt > 0
  AND (fm.mar_cnt - fm.feb_cnt) * 1.0 / fm.feb_cnt > 0.20
ORDER BY percent_increase DESC, h.hub_name;