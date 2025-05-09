SELECT
  CASE
    WHEN t."Milliseconds" < 180000 THEN 'Short'
    WHEN t."Milliseconds" < 300000 THEN 'Medium'
    ELSE                                  'Long'
  END                                                AS "LengthCategory",
  ROUND(MIN(t."Milliseconds") / 60000.0, 4)          AS "MinMinutes",
  ROUND(MAX(t."Milliseconds") / 60000.0, 4)          AS "MaxMinutes",
  ROUND(SUM(il."UnitPrice" * il."Quantity"), 4)      AS "TotalRevenue"
FROM "Track"        AS t
JOIN "InvoiceLine"  AS il ON il."TrackId" = t."TrackId"
GROUP BY "LengthCategory";