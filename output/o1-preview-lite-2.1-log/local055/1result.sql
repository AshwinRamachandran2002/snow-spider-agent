WITH
ArtistSales AS (
    SELECT "artists"."ArtistId", "artists"."Name", COUNT("invoice_items"."InvoiceLineId") AS "TotalTracksSold"
    FROM "artists"
    JOIN "albums" ON "artists"."ArtistId" = "albums"."ArtistId"
    JOIN "tracks" ON "albums"."AlbumId" = "tracks"."AlbumId"
    JOIN "invoice_items" ON "tracks"."TrackId" = "invoice_items"."TrackId"
    GROUP BY "artists"."ArtistId", "artists"."Name"
),
BestSellingArtist AS (
    SELECT "ArtistId"
    FROM ArtistSales
    ORDER BY "TotalTracksSold" DESC, "Name" ASC
    LIMIT 1
),
LeastSellingArtist AS (
    SELECT "ArtistId"
    FROM ArtistSales
    ORDER BY "TotalTracksSold" ASC, "Name" ASC
    LIMIT 1
),
BestArtistCustomers AS (
    SELECT DISTINCT "customers"."CustomerId"
    FROM "customers"
    JOIN "invoices" ON "customers"."CustomerId" = "invoices"."CustomerId"
    JOIN "invoice_items" ON "invoices"."InvoiceId" = "invoice_items"."InvoiceId"
    JOIN "tracks" ON "invoice_items"."TrackId" = "tracks"."TrackId"
    JOIN "albums" ON "tracks"."AlbumId" = "albums"."AlbumId"
    WHERE "albums"."ArtistId" = (SELECT "ArtistId" FROM BestSellingArtist)
),
LeastArtistCustomers AS (
    SELECT DISTINCT "customers"."CustomerId"
    FROM "customers"
    JOIN "invoices" ON "customers"."CustomerId" = "invoices"."CustomerId"
    JOIN "invoice_items" ON "invoices"."InvoiceId" = "invoice_items"."InvoiceId"
    JOIN "tracks" ON "invoice_items"."TrackId" = "tracks"."TrackId"
    JOIN "albums" ON "tracks"."AlbumId" = "albums"."AlbumId"
    WHERE "albums"."ArtistId" = (SELECT "ArtistId" FROM LeastSellingArtist)
),
CustomerSpendings AS (
    SELECT "customers"."CustomerId", SUM("invoices"."Total") AS "TotalSpent"
    FROM "customers"
    JOIN "invoices" ON "customers"."CustomerId" = "invoices"."CustomerId"
    GROUP BY "customers"."CustomerId"
),
BestArtistAvg AS (
    SELECT AVG("TotalSpent") AS "AverageSpendingBest"
    FROM CustomerSpendings
    WHERE "CustomerId" IN (SELECT "CustomerId" FROM BestArtistCustomers)
),
LeastArtistAvg AS (
    SELECT AVG("TotalSpent") AS "AverageSpendingLeast"
    FROM CustomerSpendings
    WHERE "CustomerId" IN (SELECT "CustomerId" FROM LeastArtistCustomers)
)
SELECT printf('+%.4f', ABS(BestArtistAvg."AverageSpendingBest" - LeastArtistAvg."AverageSpendingLeast")) AS "difference_in_average_spending"
FROM BestArtistAvg, LeastArtistAvg;