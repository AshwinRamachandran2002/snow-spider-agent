SELECT c."FirstName", 
       ROUND(SUM(ii."UnitPrice" * ii."Quantity"), 4) AS "AmountSpent"
FROM CHINOOK.CHINOOK.CUSTOMERS c
JOIN CHINOOK.CHINOOK.INVOICES i ON c."CustomerId" = i."CustomerId"
JOIN CHINOOK.CHINOOK.INVOICE_ITEMS ii ON i."InvoiceId" = ii."InvoiceId"
JOIN CHINOOK.CHINOOK.TRACKS t ON ii."TrackId" = t."TrackId"
JOIN CHINOOK.CHINOOK.ALBUMS al ON t."AlbumId" = al."AlbumId"
WHERE al."ArtistId" = (
    SELECT a."ArtistId"
    FROM CHINOOK.CHINOOK.ARTISTS a
    JOIN CHINOOK.CHINOOK.ALBUMS al ON a."ArtistId" = al."ArtistId"
    JOIN CHINOOK.CHINOOK.TRACKS t ON al."AlbumId" = t."AlbumId"
    JOIN CHINOOK.CHINOOK.INVOICE_ITEMS ii ON t."TrackId" = ii."TrackId"
    GROUP BY a."ArtistId"
    ORDER BY SUM(ii."UnitPrice" * ii."Quantity") DESC NULLS LAST
    LIMIT 1
)
GROUP BY c."CustomerId", c."FirstName"
HAVING SUM(ii."UnitPrice" * ii."Quantity") < 1;