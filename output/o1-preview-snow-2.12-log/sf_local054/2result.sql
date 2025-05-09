SELECT c."FirstName", ROUND(SUM(ii."UnitPrice" * ii."Quantity"), 4) AS "AmountSpent"
FROM CHINOOK.CHINOOK.CUSTOMERS c
JOIN CHINOOK.CHINOOK.INVOICES i ON c."CustomerId" = i."CustomerId"
JOIN CHINOOK.CHINOOK.INVOICE_ITEMS ii ON i."InvoiceId" = ii."InvoiceId"
JOIN CHINOOK.CHINOOK.TRACKS t ON ii."TrackId" = t."TrackId"
JOIN CHINOOK.CHINOOK.ALBUMS a ON t."AlbumId" = a."AlbumId"
WHERE a."ArtistId" = 90
GROUP BY c."CustomerId", c."FirstName"
HAVING SUM(ii."UnitPrice" * ii."Quantity") < 1;