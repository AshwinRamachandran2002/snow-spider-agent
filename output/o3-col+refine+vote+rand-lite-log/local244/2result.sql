SELECT
    CASE
        WHEN t."Milliseconds" < 180000 THEN 'Short'
        WHEN t."Milliseconds" <= 360000 THEN 'Medium'
        ELSE 'Long'
    END                                                      AS "Duration_Category",
    ROUND(MIN(t."Milliseconds") / 60000.0, 2)                AS "Min_Minutes",
    ROUND(MAX(t."Milliseconds") / 60000.0, 2)                AS "Max_Minutes",
    ROUND(SUM(il."UnitPrice" * il."Quantity"), 2)            AS "Total_Revenue"
FROM "Track"        AS t
JOIN "InvoiceLine"  AS il ON il."TrackId" = t."TrackId"
GROUP BY "Duration_Category";