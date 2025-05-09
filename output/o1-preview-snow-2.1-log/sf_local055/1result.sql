WITH ArtistSales AS (
  SELECT
    AR."ArtistId",
    AR."Name",
    COUNT(II."InvoiceLineId") AS "TracksSold"
  FROM
    CHINOOK.CHINOOK.ARTISTS AR
    JOIN CHINOOK.CHINOOK.ALBUMS A ON AR."ArtistId" = A."ArtistId"
    JOIN CHINOOK.CHINOOK.TRACKS T ON A."AlbumId" = T."AlbumId"
    JOIN CHINOOK.CHINOOK.INVOICE_ITEMS II ON T."TrackId" = II."TrackId"
  GROUP BY
    AR."ArtistId",
    AR."Name"
),
BestSellingArtist AS (
  SELECT "ArtistId"
  FROM ArtistSales
  WHERE "TracksSold" = (SELECT MAX("TracksSold") FROM ArtistSales)
  ORDER BY "Name" ASC
  LIMIT 1
),
LeastSellingArtist AS (
  SELECT "ArtistId"
  FROM ArtistSales
  WHERE "TracksSold" = (SELECT MIN("TracksSold") FROM ArtistSales)
  ORDER BY "Name" ASC
  LIMIT 1
),
BestAvgSpending AS (
  SELECT AVG("TotalSpending") AS "AvgSpending"
  FROM (
    SELECT
      C."CustomerId",
      SUM(I."Total") AS "TotalSpending"
    FROM
      CHINOOK.CHINOOK.CUSTOMERS C
      JOIN CHINOOK.CHINOOK.INVOICES I ON C."CustomerId" = I."CustomerId"
      JOIN CHINOOK.CHINOOK.INVOICE_ITEMS II ON I."InvoiceId" = II."InvoiceId"
      JOIN CHINOOK.CHINOOK.TRACKS T ON II."TrackId" = T."TrackId"
      JOIN CHINOOK.CHINOOK.ALBUMS A ON T."AlbumId" = A."AlbumId"
    WHERE A."ArtistId" = (SELECT "ArtistId" FROM BestSellingArtist)
    GROUP BY C."CustomerId"
  )
),
LeastAvgSpending AS (
  SELECT AVG("TotalSpending") AS "AvgSpending"
  FROM (
    SELECT
      C."CustomerId",
      SUM(I."Total") AS "TotalSpending"
    FROM
      CHINOOK.CHINOOK.CUSTOMERS C
      JOIN CHINOOK.CHINOOK.INVOICES I ON C."CustomerId" = I."CustomerId"
      JOIN CHINOOK.CHINOOK.INVOICE_ITEMS II ON I."InvoiceId" = II."InvoiceId"
      JOIN CHINOOK.CHINOOK.TRACKS T ON II."TrackId" = T."TrackId"
      JOIN CHINOOK.CHINOOK.ALBUMS A ON T."AlbumId" = A."AlbumId"
    WHERE A."ArtistId" = (SELECT "ArtistId" FROM LeastSellingArtist)
    GROUP BY C."CustomerId"
  )
)
SELECT ROUND(ABS(BestAvgSpending."AvgSpending" - LeastAvgSpending."AvgSpending"), 4) AS "Difference in average spending"
FROM BestAvgSpending, LeastAvgSpending;