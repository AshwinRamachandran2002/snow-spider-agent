SELECT
    CASE
        WHEN t."Milliseconds" < 180000 THEN 'short'
        WHEN t."Milliseconds" <= 300000 THEN 'medium'
        ELSE 'long'
    END AS "LengthCategory",
    ROUND(MIN(t."Milliseconds") / 60000.0, 4) AS "MinMinutes",
    ROUND(MAX(t."Milliseconds") / 60000.0, 4) AS "MaxMinutes",
    ROUND(SUM(il."UnitPrice" * il."Quantity"), 4) AS "TotalRevenue"
FROM "Track" AS t
JOIN "InvoiceLine" AS il
  ON t."TrackId" = il."TrackId"
GROUP BY 1
ORDER BY
    CASE
        WHEN "LengthCategory" = 'short'  THEN 1
        WHEN "LengthCategory" = 'medium' THEN 2
        ELSE 3
    END;