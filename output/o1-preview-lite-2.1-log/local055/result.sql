WITH
ArtistsSales AS (
    SELECT "artists"."ArtistId", "artists"."Name", SUM("invoice_items"."Quantity") AS "TotalQuantitySold"
    FROM "invoice_items"
    JOIN "tracks" ON "invoice_items"."TrackId" = "tracks"."TrackId"
    JOIN "albums" ON "tracks"."AlbumId" = "albums"."AlbumId"
    JOIN "artists" ON "albums"."ArtistId" = "artists"."ArtistId"
    GROUP BY "artists"."ArtistId"
),
BestSellingArtist AS (
    SELECT "ArtistId"
    FROM ArtistsSales
    ORDER BY "TotalQuantitySold" DESC, "Name" ASC
    LIMIT 1
),
LeastSellingArtist AS (
    SELECT "ArtistId"
    FROM ArtistsSales
    WHERE "TotalQuantitySold" > 0
    ORDER BY "TotalQuantitySold" ASC, "Name" ASC
    LIMIT 1
),
CustomersBest AS (
    SELECT DISTINCT "customers"."CustomerId"
    FROM "customers"
    JOIN "invoices" ON "customers"."CustomerId" = "invoices"."CustomerId"
    JOIN "invoice_items" ON "invoices"."InvoiceId" = "invoice_items"."InvoiceId"
    JOIN "tracks" ON "invoice_items"."TrackId" = "tracks"."TrackId"
    JOIN "albums" ON "tracks"."AlbumId" = "albums"."AlbumId"
    WHERE "albums"."ArtistId" = (SELECT "ArtistId" FROM BestSellingArtist)
),
CustomersLeast AS (
    SELECT DISTINCT "customers"."CustomerId"
    FROM "customers"
    JOIN "invoices" ON "customers"."CustomerId" = "invoices"."CustomerId"
    JOIN "invoice_items" ON "invoices"."InvoiceId" = "invoice_items"."InvoiceId"
    JOIN "tracks" ON "invoice_items"."TrackId" = "tracks"."TrackId"
    JOIN "albums" ON "tracks"."AlbumId" = "albums"."AlbumId"
    WHERE "albums"."ArtistId" = (SELECT "ArtistId" FROM LeastSellingArtist)
),
AverageSpendingBest AS (
    SELECT AVG("invoices"."Total") AS "AvgSpendingBest"
    FROM "invoices"
    WHERE "invoices"."CustomerId" IN (SELECT "CustomerId" FROM CustomersBest)
),
AverageSpendingLeast AS (
    SELECT AVG("invoices"."Total") AS "AvgSpendingLeast"
    FROM "invoices"
    WHERE "invoices"."CustomerId" IN (SELECT "CustomerId" FROM CustomersLeast)
)
SELECT ROUND(ABS(AverageSpendingBest."AvgSpendingBest" - AverageSpendingLeast."AvgSpendingLeast"), 4) AS "difference_in_average_spending"
FROM AverageSpendingBest, AverageSpendingLeast;