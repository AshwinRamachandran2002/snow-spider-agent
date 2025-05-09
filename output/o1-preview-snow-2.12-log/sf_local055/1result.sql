WITH ArtistSales AS (
    SELECT ar."ArtistId", ar."Name" AS "ArtistName", SUM(ii."UnitPrice" * ii."Quantity") AS "TotalSales"
    FROM "CHINOOK"."CHINOOK"."INVOICE_ITEMS" ii
    JOIN "CHINOOK"."CHINOOK"."TRACKS" t ON ii."TrackId" = t."TrackId"
    JOIN "CHINOOK"."CHINOOK"."ALBUMS" al ON t."AlbumId" = al."AlbumId"
    JOIN "CHINOOK"."CHINOOK"."ARTISTS" ar ON al."ArtistId" = ar."ArtistId"
    GROUP BY ar."ArtistId", ar."Name"
),
TopArtist AS (
    SELECT "ArtistId", "ArtistName", "TotalSales"
    FROM ArtistSales
    ORDER BY "TotalSales" DESC NULLS LAST, "ArtistName" ASC
    LIMIT 1
),
LowArtist AS (
    SELECT "ArtistId", "ArtistName", "TotalSales"
    FROM ArtistSales
    ORDER BY "TotalSales" ASC NULLS LAST, "ArtistName" ASC
    LIMIT 1
),
TopArtistSpending AS (
    SELECT c."CustomerId", SUM(ii."UnitPrice" * ii."Quantity") AS "AmountSpent"
    FROM "CHINOOK"."CHINOOK"."CUSTOMERS" c
    JOIN "CHINOOK"."CHINOOK"."INVOICES" i ON c."CustomerId" = i."CustomerId"
    JOIN "CHINOOK"."CHINOOK"."INVOICE_ITEMS" ii ON i."InvoiceId" = ii."InvoiceId"
    JOIN "CHINOOK"."CHINOOK"."TRACKS" t ON ii."TrackId" = t."TrackId"
    JOIN "CHINOOK"."CHINOOK"."ALBUMS" al ON t."AlbumId" = al."AlbumId"
    WHERE al."ArtistId" = (SELECT "ArtistId" FROM TopArtist)
    GROUP BY c."CustomerId"
),
LowArtistSpending AS (
    SELECT c."CustomerId", SUM(ii."UnitPrice" * ii."Quantity") AS "AmountSpent"
    FROM "CHINOOK"."CHINOOK"."CUSTOMERS" c
    JOIN "CHINOOK"."CHINOOK"."INVOICES" i ON c."CustomerId" = i."CustomerId"
    JOIN "CHINOOK"."CHINOOK"."INVOICE_ITEMS" ii ON i."InvoiceId" = ii."InvoiceId"
    JOIN "CHINOOK"."CHINOOK"."TRACKS" t ON ii."TrackId" = t."TrackId"
    JOIN "CHINOOK"."CHINOOK"."ALBUMS" al ON t."AlbumId" = al."AlbumId"
    WHERE al."ArtistId" = (SELECT "ArtistId" FROM LowArtist)
    GROUP BY c."CustomerId"
),
AverageTopArtistSpending AS (
    SELECT AVG("AmountSpent") AS "AverageSpending" FROM TopArtistSpending
),
AverageLowArtistSpending AS (
    SELECT AVG("AmountSpent") AS "AverageSpending" FROM LowArtistSpending
)
SELECT ROUND(ABS(
    (SELECT "AverageSpending" FROM AverageTopArtistSpending) -
    (SELECT "AverageSpending" FROM AverageLowArtistSpending)
), 4) AS "AbsoluteDifference";