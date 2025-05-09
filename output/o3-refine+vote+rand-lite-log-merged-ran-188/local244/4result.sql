WITH track_classification AS (
    SELECT
        TrackId,
        Milliseconds / 60000.0 AS minutes,               -- duration in minutes
        CASE
            WHEN Milliseconds < 180000                THEN 'Short'   -- < 3 minutes
            WHEN Milliseconds < 300000                THEN 'Medium'  -- 3‑5 minutes
            ELSE                                           'Long'    -- ≥ 5 minutes
        END AS category
    FROM Track
),
track_revenue AS (
    SELECT
        TrackId,
        SUM(UnitPrice * Quantity) AS revenue
    FROM InvoiceLine
    GROUP BY TrackId
)
SELECT
    c.category,
    ROUND(MIN(c.minutes), 4)  AS min_minutes,
    ROUND(MAX(c.minutes), 4)  AS max_minutes,
    ROUND(COALESCE(SUM(r.revenue), 0), 4) AS total_revenue
FROM track_classification AS c
LEFT JOIN track_revenue AS r USING (TrackId)
GROUP BY c.category
ORDER BY CASE c.category
            WHEN 'Short'  THEN 1
            WHEN 'Medium' THEN 2
            WHEN 'Long'   THEN 3
         END;