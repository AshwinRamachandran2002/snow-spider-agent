SELECT
    Category                               AS category,
    ROUND(MIN(Minutes), 4)                 AS min_duration_minutes,
    ROUND(MAX(Minutes), 4)                 AS max_duration_minutes,
    ROUND(SUM(Revenue), 4)                 AS total_revenue
FROM (
    SELECT
        t."TrackId",
        t."Milliseconds" / 60000.0                         AS Minutes,
        CASE
            WHEN t."Milliseconds" < 180000 THEN 'Short'
            WHEN t."Milliseconds" BETWEEN 180000 AND 300000 THEN 'Medium'
            ELSE 'Long'
        END                                               AS Category,
        il."UnitPrice" * il."Quantity"                    AS Revenue
    FROM "Track" t
    JOIN "InvoiceLine" il ON t."TrackId" = il."TrackId"
)
GROUP BY Category;