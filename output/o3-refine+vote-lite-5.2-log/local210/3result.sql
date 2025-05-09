WITH finished_orders AS (
    SELECT
        o."order_id",
        o."store_id",
        /* Derive the finishing month from the non‑ISO date string or, if parsable, with strftime */
        CASE
            WHEN o."order_moment_finished" LIKE '%/%/%'
                 THEN CAST(
                          SUBSTR(o."order_moment_finished",
                                 1,
                                 INSTR(o."order_moment_finished", '/') - 1) AS INTEGER)
            ELSE CAST(strftime('%m', o."order_moment_finished") AS INTEGER)
        END AS finish_month
    FROM "orders" o
    WHERE o."order_moment_finished" IS NOT NULL
      AND o."order_status" = 'FINISHED'
),
monthly_counts AS (
    SELECT
        h."hub_id",
        h."hub_name",
        SUM(CASE WHEN f.finish_month = 2 THEN 1 ELSE 0 END) AS feb_finished,
        SUM(CASE WHEN f.finish_month = 3 THEN 1 ELSE 0 END) AS mar_finished
    FROM finished_orders f
    JOIN "stores" s ON f."store_id" = s."store_id"
    JOIN "hubs"   h ON s."hub_id"  = h."hub_id"
    GROUP BY h."hub_id", h."hub_name"
)
SELECT
    "hub_id",
    "hub_name",
    feb_finished,
    mar_finished,
    CASE
        WHEN feb_finished = 0 THEN NULL
        ELSE ROUND((mar_finished - feb_finished) * 100.0 / feb_finished, 2)
    END AS percent_increase
FROM monthly_counts
WHERE feb_finished > 0
  AND mar_finished > feb_finished * 1.20
ORDER BY percent_increase DESC, "hub_id";