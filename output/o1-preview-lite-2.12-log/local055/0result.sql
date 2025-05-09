WITH ArtistSales AS (
    SELECT ar."ArtistId", ar."Name" AS "ArtistName", COALESCE(SUM(ii."UnitPrice" * ii."Quantity"), 0) AS "TotalSales"
    FROM "artists" AS ar
    LEFT JOIN "albums" AS al ON ar."ArtistId" = al."ArtistId"
    LEFT JOIN "tracks" AS t ON al."AlbumId" = t."AlbumId"
    LEFT JOIN "invoice_items" AS ii ON t."TrackId" = ii."TrackId"
    GROUP BY ar."ArtistId", ar."Name"
),
TopArtist AS (
    SELECT "ArtistId", "ArtistName"
    FROM ArtistSales
    ORDER BY "TotalSales" DESC, "ArtistName" ASC
    LIMIT 1
),
LowestArtist AS (
    SELECT "ArtistId", "ArtistName"
    FROM ArtistSales
    ORDER BY "TotalSales" ASC, "ArtistName" ASC
    LIMIT 1
),
TopArtistCustomerSpending AS (
    SELECT c."CustomerId", SUM(ii."UnitPrice" * ii."Quantity") AS "TotalSpent"
    FROM "customers" AS c
    JOIN "invoices" AS i ON c."CustomerId" = i."CustomerId"
    JOIN "invoice_items" AS ii ON i."InvoiceId" = ii."InvoiceId"
    JOIN "tracks" AS t ON ii."TrackId" = t."TrackId"
    JOIN "albums" AS al ON t."AlbumId" = al."AlbumId"
    JOIN TopArtist AS ta ON al."ArtistId" = ta."ArtistId"
    GROUP BY c."CustomerId"
),
LowestArtistCustomerSpending AS (
    SELECT c."CustomerId", SUM(ii."UnitPrice" * ii."Quantity") AS "TotalSpent"
    FROM "customers" AS c
    JOIN "invoices" AS i ON c."CustomerId" = i."CustomerId"
    JOIN "invoice_items" AS ii ON i."InvoiceId" = ii."InvoiceId"
    JOIN "tracks" AS t ON ii."TrackId" = t."TrackId"
    JOIN "albums" AS al ON t."AlbumId" = al."AlbumId"
    JOIN LowestArtist AS la ON al."ArtistId" = la."ArtistId"
    GROUP BY c."CustomerId"
),
TopArtistAvg AS (
    SELECT AVG("TotalSpent") AS "AvgSpent"
    FROM TopArtistCustomerSpending
),
LowestArtistAvg AS (
    SELECT COALESCE(AVG("TotalSpent"), 0) AS "AvgSpent"
    FROM LowestArtistCustomerSpending
)
SELECT ABS(ROUND(TopArtistAvg."AvgSpent" - LowestArtistAvg."AvgSpent", 4)) AS "difference"
FROM TopArtistAvg, LowestArtistAvg;