SELECT c."FirstName", ROUND(SUM(ii."UnitPrice" * ii."Quantity"), 4) AS "AmountSpent"
FROM "CHINOOK"."CHINOOK"."CUSTOMERS" c
JOIN "CHINOOK"."CHINOOK"."INVOICES" i ON c."CustomerId" = i."CustomerId"
JOIN "CHINOOK"."CHINOOK"."INVOICE_ITEMS" ii ON i."InvoiceId" = ii."InvoiceId"
JOIN "CHINOOK"."CHINOOK"."TRACKS" t ON ii."TrackId" = t."TrackId"
JOIN "CHINOOK"."CHINOOK"."ALBUMS" a ON t."AlbumId" = a."AlbumId"
WHERE a."ArtistId" = (
    SELECT a2."ArtistId"
    FROM "CHINOOK"."CHINOOK"."ALBUMS" a2
    JOIN "CHINOOK"."CHINOOK"."TRACKS" t2 ON a2."AlbumId" = t2."AlbumId"
    JOIN "CHINOOK"."CHINOOK"."INVOICE_ITEMS" ii2 ON t2."TrackId" = ii2."TrackId"
    GROUP BY a2."ArtistId"
    ORDER BY SUM(ii2."UnitPrice" * ii2."Quantity") DESC NULLS LAST
    LIMIT 1
)
GROUP BY c."CustomerId", c."FirstName"
HAVING SUM(ii."UnitPrice" * ii."Quantity") < 1;