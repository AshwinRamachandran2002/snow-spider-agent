WITH TotalSalesPerCountry AS (
  SELECT c."Country", SUM(i."Total") AS "TotalSales"
  FROM "invoices" i
  JOIN "customers" c ON i."CustomerId" = c."CustomerId"
  WHERE c."Country" IN (
    SELECT "Country"
    FROM "customers"
    GROUP BY "Country"
    HAVING COUNT("CustomerId") > 4
  )
  GROUP BY c."Country"
),
RankedTotalSales AS (
  SELECT
    "TotalSales",
    ROW_NUMBER() OVER (ORDER BY "TotalSales" ASC) AS RN,
    COUNT(*) OVER () AS CNT
  FROM TotalSalesPerCountry
),
MedianTotal AS (
  SELECT "TotalSales"
  FROM RankedTotalSales
  WHERE
    (CNT % 2 = 1 AND RN = (CNT + 1) / 2)
    OR
    (CNT % 2 = 0 AND (RN = CNT / 2 OR RN = CNT / 2 + 1))
)
SELECT ROUND(AVG("TotalSales"), 4) AS "Median_Total_Sales"
FROM MedianTotal
;