SELECT
        cat."LengthCategory",
        ROUND(MIN(cat."DurationMinutes"), 2) AS "MinMinutes",
        ROUND(MAX(cat."DurationMinutes"), 2) AS "MaxMinutes",
        ROUND(SUM(il."UnitPrice" * il."Quantity"), 2) AS "TotalRevenue"
FROM   (
        SELECT
               "TrackId",
               "Milliseconds" / 60000.0 AS "DurationMinutes",
               CASE
                   WHEN "Milliseconds" < 180000 THEN 'Short'
                   WHEN "Milliseconds" < 300000 THEN 'Medium'
                   ELSE 'Long'
               END AS "LengthCategory"
        FROM   "Track"
       ) AS cat
JOIN   "InvoiceLine" AS il
       ON il."TrackId" = cat."TrackId"
GROUP BY cat."LengthCategory";