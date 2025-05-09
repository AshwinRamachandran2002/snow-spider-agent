SELECT
  DurationCategory AS "Track_Length_Category",
  ROUND(MIN(DurationMinutes), 4) AS "Min_Time",
  ROUND(MAX(DurationMinutes), 4) AS "Max_Time",
  ROUND(SUM(TotalRevenue), 4) AS "Total_Revenue"
FROM (
  SELECT
    t."TrackId",
    (t."Milliseconds" / 60000.0) AS DurationMinutes,
    CASE
      WHEN (t."Milliseconds" / 60000.0) < 3 THEN 'short'
      WHEN (t."Milliseconds" / 60000.0) BETWEEN 3 AND 5 THEN 'medium'
      ELSE 'long'
    END AS DurationCategory,
    SUM(il."UnitPrice" * il."Quantity") AS TotalRevenue
  FROM "Track" t
  JOIN "InvoiceLine" il ON t."TrackId" = il."TrackId"
  GROUP BY t."TrackId"
) sub
GROUP BY DurationCategory;