WITH finished_orders AS (
    SELECT  o.order_id,
            s.hub_id,
            o.order_created_year  AS year,
            o.order_created_month AS month
    FROM    orders  o
    JOIN    stores  s ON s.store_id = o.store_id
    WHERE   o.order_status = 'FINISHED'
),
monthly_counts AS (
    SELECT  hub_id,
            year,
            month,
            COUNT(*) AS finished_qty
    FROM    finished_orders
    GROUP BY hub_id, year, month
),
feb_vs_mar AS (
    SELECT  feb.hub_id,
            feb.finished_qty AS feb_qty,
            mar.finished_qty AS mar_qty,
            (CAST(mar.finished_qty AS REAL) / feb.finished_qty) - 1.0 AS pct_growth
    FROM    monthly_counts feb
    JOIN    monthly_counts mar
           ON mar.hub_id = feb.hub_id
          AND mar.year   = feb.year
    WHERE   feb.month = 2
      AND   mar.month = 3
)
SELECT  DISTINCT h.hub_id,
                 h.hub_name
FROM    feb_vs_mar  fm
JOIN    hubs        h ON h.hub_id = fm.hub_id
WHERE   fm.pct_growth > 0.20;