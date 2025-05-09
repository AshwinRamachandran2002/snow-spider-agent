WITH best_selling_artist AS (
    SELECT al."ArtistId"
    FROM "albums" AS al
    JOIN "tracks"        AS tr ON tr."AlbumId" = al."AlbumId"
    JOIN "invoice_items" AS ii ON ii."TrackId" = tr."TrackId"
    GROUP BY al."ArtistId"
    ORDER BY SUM(ii."UnitPrice" * ii."Quantity") DESC
    LIMIT 1
)
SELECT cu."FirstName",
       ROUND(SUM(ii."UnitPrice" * ii."Quantity"), 2) AS "AmountSpent"
FROM "customers"      AS cu
JOIN "invoices"       AS inv ON inv."CustomerId" = cu."CustomerId"
JOIN "invoice_items"  AS ii  ON ii."InvoiceId"   = inv."InvoiceId"
JOIN "tracks"         AS tr  ON tr."TrackId"     = ii."TrackId"
JOIN "albums"         AS al  ON al."AlbumId"     = tr."AlbumId"
WHERE al."ArtistId" = (SELECT "ArtistId" FROM best_selling_artist)
GROUP BY cu."CustomerId"
HAVING SUM(ii."UnitPrice" * ii."Quantity") < 1
ORDER BY "AmountSpent" DESC;