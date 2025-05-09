WITH TrackDurations AS (
    SELECT
        "TrackId",
        "Milliseconds",
        "Milliseconds" / 60000.0          AS DurationMinutes,
        CASE
            WHEN "Milliseconds" < 180000                THEN 'Short'
            WHEN "Milliseconds" <= 360000               THEN 'Medium'
            ELSE                                             'Long'
        END                                           AS Category
    FROM "Track"
),
RevenuePerTrack AS (
    SELECT
        "TrackId",
        SUM("UnitPrice" * "Quantity") AS Revenue
    FROM "InvoiceLine"
    GROUP BY "TrackId"
)
SELECT
    td.Category,
    ROUND(MIN(td.DurationMinutes),4)                  AS MinMinutes,
    ROUND(MAX(td.DurationMinutes),4)                  AS MaxMinutes,
    ROUND(SUM(COALESCE(rp.Revenue,0)),4)              AS TotalRevenue
FROM TrackDurations td
LEFT JOIN RevenuePerTrack rp ON td."TrackId" = rp."TrackId"
GROUP BY td.Category
ORDER BY CASE td.Category 
            WHEN 'Short'  THEN 1
            WHEN 'Medium' THEN 2
            WHEN 'Long'   THEN 3
         END;