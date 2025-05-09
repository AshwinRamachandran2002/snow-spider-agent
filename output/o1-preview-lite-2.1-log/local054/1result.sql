SELECT "customers"."FirstName",
       ROUND(SUM("invoice_items"."UnitPrice" * "invoice_items"."Quantity"), 4) AS "AmountSpent"
FROM "customers"
JOIN "invoices" ON "customers"."CustomerId" = "invoices"."CustomerId"
JOIN "invoice_items" ON "invoices"."InvoiceId" = "invoice_items"."InvoiceId"
JOIN "tracks" ON "invoice_items"."TrackId" = "tracks"."TrackId"
JOIN "albums" ON "tracks"."AlbumId" = "albums"."AlbumId"
WHERE "albums"."ArtistId" = (
    SELECT "albums"."ArtistId"
    FROM "invoice_items"
    JOIN "tracks" ON "invoice_items"."TrackId" = "tracks"."TrackId"
    JOIN "albums" ON "tracks"."AlbumId" = "albums"."AlbumId"
    GROUP BY "albums"."ArtistId"
    ORDER BY SUM("invoice_items"."UnitPrice" * "invoice_items"."Quantity") DESC
    LIMIT 1
)
GROUP BY "customers"."CustomerId"
HAVING SUM("invoice_items"."UnitPrice" * "invoice_items"."Quantity") < 1;