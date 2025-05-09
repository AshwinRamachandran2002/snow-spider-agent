SELECT
  Category                            AS "LengthCategory",
  ROUND(MIN(DurationMinutes), 4)      AS "MinMinutes",
  ROUND(MAX(DurationMinutes), 4)      AS "MaxMinutes",
  ROUND(SUM(LineRevenue), 4)          AS "TotalRevenue"
FROM (
  SELECT
    CASE
      WHEN t."Milliseconds" < 180000 THEN 'Short'
      WHEN t."Milliseconds" < 300000 THEN 'Medium'
      ELSE 'Long'
    END                                AS Category,
    t."Milliseconds" / 60000.0         AS DurationMinutes,
    COALESCE(il."UnitPrice" * il."Quantity", 0) AS LineRevenue
  FROM "Track" AS t
  LEFT JOIN "InvoiceLine" AS il
         ON il."TrackId" = t."TrackId"
)
GROUP BY Category;