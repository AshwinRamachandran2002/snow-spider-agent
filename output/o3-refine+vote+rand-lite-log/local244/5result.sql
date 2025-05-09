WITH track_revenue AS (
    SELECT 
        "TrackId",
        SUM("UnitPrice" * "Quantity") AS total_revenue
    FROM "InvoiceLine"
    GROUP BY "TrackId"
)
SELECT
    CASE
        WHEN t."Milliseconds" < 180000              THEN 'short'      --   < 3 minutes
        WHEN t."Milliseconds" < 300000              THEN 'medium'     -- 3–5 minutes
        ELSE                                            'long'       --   > 5 minutes
    END                                                AS category,
    ROUND( MIN(t."Milliseconds" / 60000.0), 4 )        AS min_minutes,
    ROUND( MAX(t."Milliseconds" / 60000.0), 4 )        AS max_minutes,
    ROUND( SUM( COALESCE(tr.total_revenue, 0) ), 4 )   AS total_revenue
FROM "Track" t
LEFT JOIN track_revenue tr
       ON t."TrackId" = tr."TrackId"
GROUP BY category
ORDER BY category;