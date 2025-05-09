WITH BestSellingArtist AS (
  SELECT
    "artists"."ArtistId"
  FROM "artists"
  JOIN "albums" ON "artists"."ArtistId" = "albums"."ArtistId"
  JOIN "tracks" ON "albums"."AlbumId" = "tracks"."AlbumId"
  JOIN "invoice_items" ON "tracks"."TrackId" = "invoice_items"."TrackId"
  GROUP BY "artists"."ArtistId"
  ORDER BY SUM("invoice_items"."UnitPrice" * "invoice_items"."Quantity") DESC
  LIMIT 1
)
SELECT
  "customers"."FirstName",
  ROUND(SUM("invoice_items"."UnitPrice" * "invoice_items"."Quantity"), 4) AS "AmountSpent"
FROM "customers"
JOIN "invoices" ON "customers"."CustomerId" = "invoices"."CustomerId"
JOIN "invoice_items" ON "invoices"."InvoiceId" = "invoice_items"."InvoiceId"
JOIN "tracks" ON "invoice_items"."TrackId" = "tracks"."TrackId"
JOIN "albums" ON "tracks"."AlbumId" = "albums"."AlbumId"
WHERE "albums"."ArtistId" = (SELECT "ArtistId" FROM BestSellingArtist)
GROUP BY "customers"."CustomerId"
HAVING "AmountSpent" < 1;