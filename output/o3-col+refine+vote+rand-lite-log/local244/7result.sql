WITH track_info AS (
    -- compute duration in minutes and assign a length category
    SELECT
        t."TrackId",
        t."Milliseconds" / 60000.0               AS Minutes,
        CASE
            WHEN t."Milliseconds" < 180000  THEN 'Short'   -- < 3 min
            WHEN t."Milliseconds" <= 300000 THEN 'Medium'  -- 3-5 min
            ELSE 'Long'                                    -- > 5 min
        END                                               AS LengthCategory
    FROM "Track" AS t
),
track_revenue AS (
    -- total revenue earned by each track
    SELECT
        il."TrackId",
        SUM(il."Quantity" * il."UnitPrice") AS Revenue
    FROM "InvoiceLine" AS il
    GROUP BY il."TrackId"
)
SELECT
    ti.LengthCategory,
    ROUND(MIN(ti.Minutes), 4)                AS MinMinutes,
    ROUND(MAX(ti.Minutes), 4)                AS MaxMinutes,
    ROUND(SUM(COALESCE(tr.Revenue, 0)), 4)   AS TotalRevenue
FROM track_info  AS ti
LEFT JOIN track_revenue AS tr
       ON ti."TrackId" = tr."TrackId"
GROUP BY ti.LengthCategory;