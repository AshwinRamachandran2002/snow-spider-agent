WITH ArtistSales AS (
    SELECT ar."ArtistId", ar."Name" AS "ArtistName", SUM(ii."UnitPrice" * ii."Quantity") AS "TotalSales"
    FROM "CHINOOK"."CHINOOK"."INVOICE_ITEMS" ii
    JOIN "CHINOOK"."CHINOOK"."TRACKS" t ON ii."TrackId" = t."TrackId"
    JOIN "CHINOOK"."CHINOOK"."ALBUMS" a ON t."AlbumId" = a."AlbumId"
    JOIN "CHINOOK"."CHINOOK"."ARTISTS" ar ON a."ArtistId" = ar."ArtistId"
    GROUP BY ar."ArtistId", ar."Name"
),
TopArtist AS (
    SELECT "ArtistId", "ArtistName"
    FROM ArtistSales
    ORDER BY "TotalSales" DESC NULLS LAST, "ArtistName" ASC
    LIMIT 1
),
LowestArtist AS (
    SELECT "ArtistId", "ArtistName"
    FROM ArtistSales
    ORDER BY "TotalSales" ASC NULLS LAST, "ArtistName" ASC
    LIMIT 1
),
CustomerSpending AS (
    SELECT c."CustomerId", ar."ArtistId", SUM(ii."UnitPrice" * ii."Quantity") AS "Spending"
    FROM "CHINOOK"."CHINOOK"."CUSTOMERS" c
    JOIN "CHINOOK"."CHINOOK"."INVOICES" i ON c."CustomerId" = i."CustomerId"
    JOIN "CHINOOK"."CHINOOK"."INVOICE_ITEMS" ii ON i."InvoiceId" = ii."InvoiceId"
    JOIN "CHINOOK"."CHINOOK"."TRACKS" t ON ii."TrackId" = t."TrackId"
    JOIN "CHINOOK"."CHINOOK"."ALBUMS" a ON t."AlbumId" = a."AlbumId"
    JOIN "CHINOOK"."CHINOOK"."ARTISTS" ar ON a."ArtistId" = ar."ArtistId"
    WHERE ar."ArtistId" IN (
        (SELECT "ArtistId" FROM TopArtist)
        UNION
        (SELECT "ArtistId" FROM LowestArtist)
    )
    GROUP BY c."CustomerId", ar."ArtistId"
),
AvgSpending AS (
    SELECT cs."ArtistId", ROUND(AVG(cs."Spending"), 4) AS "AverageSpending"
    FROM CustomerSpending cs
    GROUP BY cs."ArtistId"
),
Difference AS (
    SELECT ABS(
        (SELECT "AverageSpending" FROM AvgSpending WHERE "ArtistId" = (SELECT "ArtistId" FROM TopArtist))
        -
        (SELECT "AverageSpending" FROM AvgSpending WHERE "ArtistId" = (SELECT "ArtistId" FROM LowestArtist))
    ) AS "AbsoluteDifference"
)
SELECT "AbsoluteDifference"
FROM Difference;