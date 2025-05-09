-- Duration category stats (min / max minutes) and total revenue
WITH track_minutes AS (
    SELECT
        t."TrackId",
        t."Milliseconds",
        t."Milliseconds" / 60000.0            AS minutes,
        CASE
            WHEN t."Milliseconds" < 180000  THEN 'Short'   -- < 3 minutes
            WHEN t."Milliseconds" <= 300000 THEN 'Medium'  -- 3–5 minutes
            ELSE                                           'Long'    -- > 5 minutes
        END                                   AS length_category
    FROM "Track" t
),
track_revenue AS (
    SELECT
        il."TrackId",
        SUM(il."UnitPrice" * il."Quantity") AS revenue
    FROM "InvoiceLine" il
    GROUP BY il."TrackId"
)
SELECT
    tm.length_category,
    ROUND(MIN(tm.minutes), 2)          AS min_minutes,
    ROUND(MAX(tm.minutes), 2)          AS max_minutes,
    ROUND(SUM(COALESCE(tr.revenue, 0)), 2) AS total_revenue
FROM track_minutes tm
LEFT JOIN track_revenue tr
       ON tm."TrackId" = tr."TrackId"
GROUP BY tm.length_category;