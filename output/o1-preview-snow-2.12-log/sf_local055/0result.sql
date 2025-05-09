SELECT ABS(TopAvg."AverageSpending" - LowAvg."AverageSpending") AS "SpendingDifference"
FROM (
  SELECT AVG(CustomerSpent) AS "AverageSpending"
  FROM (
    SELECT C."CustomerId", SUM(II."UnitPrice" * II."Quantity") AS CustomerSpent
    FROM CHINOOK.CHINOOK.CUSTOMERS C
    JOIN CHINOOK.CHINOOK.INVOICES I ON C."CustomerId" = I."CustomerId"
    JOIN CHINOOK.CHINOOK.INVOICE_ITEMS II ON I."InvoiceId" = II."InvoiceId"
    JOIN CHINOOK.CHINOOK.TRACKS T ON II."TrackId" = T."TrackId"
    JOIN CHINOOK.CHINOOK.ALBUMS AL ON T."AlbumId" = AL."AlbumId"
    JOIN CHINOOK.CHINOOK.ARTISTS AR ON AL."ArtistId" = AR."ArtistId"
    WHERE AR."Name" = (
      SELECT AR1."Name"
      FROM CHINOOK.CHINOOK.ARTISTS AR1
      JOIN CHINOOK.CHINOOK.ALBUMS AL1 ON AR1."ArtistId" = AL1."ArtistId"
      JOIN CHINOOK.CHINOOK.TRACKS T1 ON AL1."AlbumId" = T1."AlbumId"
      JOIN CHINOOK.CHINOOK.INVOICE_ITEMS II1 ON T1."TrackId" = II1."TrackId"
      GROUP BY AR1."Name"
      ORDER BY SUM(II1."UnitPrice" * II1."Quantity") DESC NULLS LAST, AR1."Name" ASC
      LIMIT 1
    )
    GROUP BY C."CustomerId"
  ) AS TopCustomers
) AS TopAvg,
(
  SELECT AVG(CustomerSpent) AS "AverageSpending"
  FROM (
    SELECT C."CustomerId", SUM(II."UnitPrice" * II."Quantity") AS CustomerSpent
    FROM CHINOOK.CHINOOK.CUSTOMERS C
    JOIN CHINOOK.CHINOOK.INVOICES I ON C."CustomerId" = I."CustomerId"
    JOIN CHINOOK.CHINOOK.INVOICE_ITEMS II ON I."InvoiceId" = II."InvoiceId"
    JOIN CHINOOK.CHINOOK.TRACKS T ON II."TrackId" = T."TrackId"
    JOIN CHINOOK.CHINOOK.ALBUMS AL ON T."AlbumId" = AL."AlbumId"
    JOIN CHINOOK.CHINOOK.ARTISTS AR ON AL."ArtistId" = AR."ArtistId"
    WHERE AR."Name" = (
      SELECT AR2."Name"
      FROM CHINOOK.CHINOOK.ARTISTS AR2
      JOIN CHINOOK.CHINOOK.ALBUMS AL2 ON AR2."ArtistId" = AL2."ArtistId"
      JOIN CHINOOK.CHINOOK.TRACKS T2 ON AL2."AlbumId" = T2."AlbumId"
      JOIN CHINOOK.CHINOOK.INVOICE_ITEMS II2 ON T2."TrackId" = II2."TrackId"
      GROUP BY AR2."Name"
      HAVING SUM(II2."UnitPrice" * II2."Quantity") > 0
      ORDER BY SUM(II2."UnitPrice" * II2."Quantity") ASC NULLS LAST, AR2."Name" ASC
      LIMIT 1
    )
    GROUP BY C."CustomerId"
  ) AS LowCustomers
) AS LowAvg;