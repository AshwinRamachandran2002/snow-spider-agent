SELECT
    duration_category AS "Track_Length_Category",
    ROUND(MIN(duration_minutes), 4) AS Min_Time,
    ROUND(MAX(duration_minutes), 4) AS Max_Time,
    ROUND(SUM(total_revenue), 4) AS Total_Revenue
FROM (
    SELECT
        t."TrackId",
        t."Milliseconds" / 60000.0 AS duration_minutes,
        CASE
            WHEN t."Milliseconds" < 180000 THEN 'short'
            WHEN t."Milliseconds" BETWEEN 180000 AND 300000 THEN 'medium'
            ELSE 'long'
        END AS duration_category,
        COALESCE(SUM(il."UnitPrice" * il."Quantity"), 0) AS total_revenue
    FROM "Track" t
    LEFT JOIN "InvoiceLine" il ON t."TrackId" = il."TrackId"
    GROUP BY t."TrackId"
) AS track_info
GROUP BY duration_category;