WITH TrackDurations AS (
    SELECT
        "TrackId",
        "Milliseconds" / 60000.0 AS Minutes,
        CASE
            WHEN "Milliseconds" < 3 * 60000 THEN 'Short'
            WHEN "Milliseconds" < 5 * 60000 THEN 'Medium'
            ELSE 'Long'
        END AS Category
    FROM "Track"
),
RevenuePerTrack AS (
    SELECT
        "TrackId",
        SUM("UnitPrice" * "Quantity") AS Revenue
    FROM "InvoiceLine"
    GROUP BY "TrackId"
),
TrackData AS (
    SELECT
        td.Category,
        td.Minutes,
        COALESCE(rpt.Revenue, 0) AS Revenue
    FROM TrackDurations td
    LEFT JOIN RevenuePerTrack rpt USING ("TrackId")
)
SELECT
    Category,
    ROUND(MIN(Minutes), 4) AS MinMinutes,
    ROUND(MAX(Minutes), 4) AS MaxMinutes,
    ROUND(SUM(Revenue), 4) AS TotalRevenue
FROM TrackData
GROUP BY Category
ORDER BY Category;