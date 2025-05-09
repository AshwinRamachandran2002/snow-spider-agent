SELECT
    c."FirstName",
    ROUND(SUM(ii."UnitPrice" * ii."Quantity"), 2) AS "AmountSpent"
FROM "customers"      AS c
JOIN "invoices"       AS inv ON c."CustomerId" = inv."CustomerId"
JOIN "invoice_items"  AS ii  ON inv."InvoiceId" = ii."InvoiceId"
JOIN "tracks"         AS t   ON ii."TrackId"   = t."TrackId"
JOIN "albums"         AS al  ON t."AlbumId"    = al."AlbumId"
JOIN "artists"        AS ar  ON al."ArtistId"  = ar."ArtistId"
WHERE ar."ArtistId" = (
    SELECT ar2."ArtistId"
    FROM "invoice_items" AS ii2
    JOIN "tracks"        AS t2  ON ii2."TrackId" = t2."TrackId"
    JOIN "albums"        AS al2 ON t2."AlbumId"  = al2."AlbumId"
    JOIN "artists"       AS ar2 ON al2."ArtistId" = ar2."ArtistId"
    GROUP BY ar2."ArtistId"
    ORDER BY SUM(ii2."UnitPrice" * ii2."Quantity") DESC,
             ar2."ArtistId"
    LIMIT 1
)
GROUP BY c."CustomerId", c."FirstName"
HAVING SUM(ii."UnitPrice" * ii."Quantity") < 1
ORDER BY "AmountSpent" DESC, c."FirstName";