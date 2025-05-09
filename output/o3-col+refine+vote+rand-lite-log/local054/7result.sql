WITH best_artist AS (
    SELECT ar."ArtistId"
    FROM   "artists" ar
    JOIN   "albums"  al ON ar."ArtistId" = al."ArtistId"
    JOIN   "tracks"  t  ON al."AlbumId"  = t."AlbumId"
    JOIN   "invoice_items" ii ON t."TrackId" = ii."TrackId"
    GROUP  BY ar."ArtistId"
    ORDER  BY SUM(ii."UnitPrice" * ii."Quantity") DESC
    LIMIT 1
)
SELECT
    c."FirstName",
    SUM(ii."UnitPrice" * ii."Quantity") AS "Amount_Spent"
FROM "customers"     c
JOIN "invoices"      i  ON c."CustomerId" = i."CustomerId"
JOIN "invoice_items" ii ON i."InvoiceId"  = ii."InvoiceId"
JOIN "tracks"        t  ON ii."TrackId"   = t."TrackId"
JOIN "albums"        al ON t."AlbumId"    = al."AlbumId"
JOIN best_artist     ba ON al."ArtistId"  = ba."ArtistId"
GROUP BY c."CustomerId", c."FirstName"
HAVING SUM(ii."UnitPrice" * ii."Quantity") < 1;