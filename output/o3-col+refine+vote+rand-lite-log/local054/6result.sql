WITH BestSellingArtist AS (
    SELECT a."ArtistId"
    FROM "invoice_items" AS ii
    JOIN "tracks"        AS t ON ii."TrackId" = t."TrackId"
    JOIN "albums"        AS a ON t."AlbumId"  = a."AlbumId"
    GROUP BY a."ArtistId"
    ORDER BY SUM(ii."UnitPrice" * ii."Quantity") DESC
    LIMIT 1
),
CustomerArtistSpend AS (
    SELECT i."CustomerId",
           SUM(ii."UnitPrice" * ii."Quantity") AS "AmountSpent"
    FROM "invoice_items" AS ii
    JOIN "tracks"   AS t ON ii."TrackId" = t."TrackId"
    JOIN "albums"   AS a ON t."AlbumId"  = a."AlbumId"
    JOIN "invoices" AS i ON ii."InvoiceId" = i."InvoiceId"
    WHERE a."ArtistId" = (SELECT "ArtistId" FROM BestSellingArtist)
    GROUP BY i."CustomerId"
)
SELECT c."FirstName",
       ROUND(cas."AmountSpent", 2) AS "AmountSpent"
FROM CustomerArtistSpend AS cas
JOIN "customers" AS c ON c."CustomerId" = cas."CustomerId"
WHERE cas."AmountSpent" < 1;