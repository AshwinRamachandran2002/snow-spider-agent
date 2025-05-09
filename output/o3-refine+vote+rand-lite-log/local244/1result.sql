WITH track_class AS (
    SELECT
        "TrackId",
        ("Milliseconds" / 60000.0)                       AS minutes,
        CASE
            WHEN ("Milliseconds" / 60000.0) < 3  THEN 'Short'
            WHEN ("Milliseconds" / 60000.0) < 6  THEN 'Medium'
            ELSE 'Long'
        END                                             AS category
    FROM "Track"
),
track_sales AS (
    SELECT
        "TrackId",
        SUM("UnitPrice" * "Quantity") AS revenue
    FROM "InvoiceLine"
    GROUP BY "TrackId"
)
SELECT
    tc.category,
    ROUND(MIN(tc.minutes),4)          AS min_minutes,
    ROUND(MAX(tc.minutes),4)          AS max_minutes,
    ROUND(SUM(COALESCE(ts.revenue,0)),4) AS total_revenue
FROM track_class tc
LEFT JOIN track_sales ts USING ("TrackId")
GROUP BY tc.category
ORDER BY CASE tc.category
            WHEN 'Short'  THEN 1
            WHEN 'Medium' THEN 2
            ELSE 3
         END;