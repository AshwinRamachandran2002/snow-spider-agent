WITH track_durations AS (
    SELECT
        t."TrackId",
        t."Milliseconds" / 60000.0                    AS minutes,
        CASE
            WHEN t."Milliseconds" < 180000            THEN 'short'   -- < 3 minutes
            WHEN t."Milliseconds" <= 300000           THEN 'medium'  -- 3–5 minutes
            ELSE                                            'long'    -- > 5 minutes
        END                                           AS category
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
    td.category,
    ROUND(MIN(td.minutes),4)             AS min_minutes,
    ROUND(MAX(td.minutes),4)             AS max_minutes,
    ROUND(SUM(COALESCE(tr.revenue,0)),4) AS total_revenue
FROM track_durations td
LEFT JOIN track_revenue tr
       ON tr."TrackId" = td."TrackId"
GROUP BY td.category
ORDER BY td.category;