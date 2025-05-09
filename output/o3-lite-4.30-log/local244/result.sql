SELECT 
    cat.length_category AS category,
    cat.min_duration_minutes,
    cat.max_duration_minutes,
    ROUND(rev.total_revenue, 4) AS total_revenue
FROM (
    SELECT
        CASE
            WHEN "Milliseconds" < 180000 THEN 'short'
            WHEN "Milliseconds" <= 300000 THEN 'medium'
            ELSE 'long'
        END AS length_category,
        ROUND(MIN("Milliseconds") / 60000.0, 4) AS min_duration_minutes,
        ROUND(MAX("Milliseconds") / 60000.0, 4) AS max_duration_minutes
    FROM "Track"
    GROUP BY length_category
) AS cat
JOIN (
    SELECT
        CASE
            WHEN t."Milliseconds" < 180000 THEN 'short'
            WHEN t."Milliseconds" <= 300000 THEN 'medium'
            ELSE 'long'
        END AS length_category,
        ROUND(SUM(il."UnitPrice" * il."Quantity"), 4) AS total_revenue
    FROM "InvoiceLine" AS il
    JOIN "Track"        AS t ON t."TrackId" = il."TrackId"
    GROUP BY length_category
) AS rev
ON cat.length_category = rev.length_category
ORDER BY 
    CASE cat.length_category
        WHEN 'short'  THEN 1
        WHEN 'medium' THEN 2
        ELSE 3
    END;