WITH
TotalSalesPerArtist AS (
    SELECT ar."ArtistId", ar."Name", COALESCE(SUM(ii."UnitPrice" * ii."Quantity"), 0) AS "TotalSales"
    FROM "artists" ar
    LEFT JOIN "albums" al ON ar."ArtistId" = al."ArtistId"
    LEFT JOIN "tracks" t ON al."AlbumId" = t."AlbumId"
    LEFT JOIN "invoice_items" ii ON t."TrackId" = ii."TrackId"
    GROUP BY ar."ArtistId", ar."Name"
),
TopArtist AS (
    SELECT "ArtistId", "Name", "TotalSales"
    FROM TotalSalesPerArtist
    ORDER BY "TotalSales" DESC, "Name" ASC
    LIMIT 1
),
LowestArtist AS (
    SELECT "ArtistId", "Name", "TotalSales"
    FROM TotalSalesPerArtist
    WHERE "TotalSales" > 0
    ORDER BY "TotalSales" ASC, "Name" ASC
    LIMIT 1
),
TopArtistCustomerSpending AS (
    SELECT c."CustomerId", SUM(ii."UnitPrice" * ii."Quantity") AS "TotalSpent"
    FROM "customers" c
    JOIN "invoices" inv ON c."CustomerId" = inv."CustomerId"
    JOIN "invoice_items" ii ON inv."InvoiceId" = ii."InvoiceId"
    JOIN "tracks" t ON ii."TrackId" = t."TrackId"
    JOIN "albums" al ON t."AlbumId" = al."AlbumId"
    JOIN TopArtist ta ON al."ArtistId" = ta."ArtistId"
    GROUP BY c."CustomerId"
),
LowestArtistCustomerSpending AS (
    SELECT c."CustomerId", SUM(ii."UnitPrice" * ii."Quantity") AS "TotalSpent"
    FROM "customers" c
    JOIN "invoices" inv ON c."CustomerId" = inv."CustomerId"
    JOIN "invoice_items" ii ON inv."InvoiceId" = ii."InvoiceId"
    JOIN "tracks" t ON ii."TrackId" = t."TrackId"
    JOIN "albums" al ON t."AlbumId" = al."AlbumId"
    JOIN LowestArtist la ON al."ArtistId" = la."ArtistId"
    GROUP BY c."CustomerId"
),
AvgTopArtistSpending AS (
    SELECT AVG("TotalSpent") AS "AvgSpent" FROM TopArtistCustomerSpending
),
AvgLowestArtistSpending AS (
    SELECT AVG("TotalSpent") AS "AvgSpent" FROM LowestArtistCustomerSpending
)
SELECT ROUND(ABS(ats."AvgSpent" - als."AvgSpent"), 4) AS "difference"
FROM AvgTopArtistSpending ats, AvgLowestArtistSpending als;