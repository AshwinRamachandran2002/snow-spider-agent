WITH best_selling_artist AS (
    SELECT ar."ArtistId"
    FROM "artists" ar
    JOIN "albums"  al ON al."ArtistId" = ar."ArtistId"
    JOIN "tracks"  t  ON t."AlbumId"   = al."AlbumId"
    JOIN "invoice_items" ii ON ii."TrackId" = t."TrackId"
    GROUP BY ar."ArtistId"
    ORDER BY SUM(ii."UnitPrice" * ii."Quantity") DESC
    LIMIT 1
)
SELECT
    c."FirstName",
    ROUND(SUM(ii."UnitPrice" * ii."Quantity"), 4) AS "amount_spent"
FROM "customers" c
JOIN "invoices"      inv ON inv."CustomerId" = c."CustomerId"
JOIN "invoice_items" ii  ON ii."InvoiceId"   = inv."InvoiceId"
JOIN "tracks"        t   ON t."TrackId"      = ii."TrackId"
JOIN "albums"        al  ON al."AlbumId"     = t."AlbumId"
WHERE al."ArtistId" = (SELECT "ArtistId" FROM best_selling_artist)
GROUP BY c."CustomerId"
HAVING SUM(ii."UnitPrice" * ii."Quantity") < 1
ORDER BY "amount_spent" DESC;