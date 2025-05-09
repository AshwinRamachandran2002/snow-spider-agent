WITH
AlbumSales AS (
    SELECT
        t."AlbumId",
        SUM(ii."UnitPrice" * ii."Quantity") AS "AlbumSales"
    FROM
        "invoice_items" ii
    JOIN "tracks" t ON ii."TrackId" = t."TrackId"
    GROUP BY t."AlbumId"
),
ArtistAlbumSales AS (
    SELECT
        al."ArtistId",
        SUM(a."AlbumSales") AS "TotalArtistAlbumSales"
    FROM
        AlbumSales a
    JOIN "albums" al ON a."AlbumId" = al."AlbumId"
    GROUP BY al."ArtistId"
),
TopArtist AS (
    SELECT "ArtistId"
    FROM ArtistAlbumSales
    ORDER BY "TotalArtistAlbumSales" DESC, "ArtistId" ASC
    LIMIT 1
),
LowestArtist AS (
    SELECT "ArtistId"
    FROM ArtistAlbumSales
    WHERE "TotalArtistAlbumSales" > 0
    ORDER BY "TotalArtistAlbumSales" ASC, "ArtistId" ASC
    LIMIT 1
),
CustomerSpendings AS (
    SELECT
        c."CustomerId",
        a."ArtistId",
        SUM(ii."UnitPrice" * ii."Quantity") AS "ArtistSpending"
    FROM
        "customers" c
    JOIN "invoices" i ON c."CustomerId" = i."CustomerId"
    JOIN "invoice_items" ii ON i."InvoiceId" = ii."InvoiceId"
    JOIN "tracks" t ON ii."TrackId" = t."TrackId"
    JOIN "albums" al ON t."AlbumId" = al."AlbumId"
    JOIN "artists" a ON al."ArtistId" = a."ArtistId"
    WHERE a."ArtistId" IN (
        SELECT "ArtistId" FROM TopArtist
        UNION ALL
        SELECT "ArtistId" FROM LowestArtist
    )
    GROUP BY c."CustomerId", a."ArtistId"
),
AverageSpendings AS (
    SELECT
        cs."ArtistId",
        AVG(cs."ArtistSpending") AS "AvgSpending"
    FROM
        CustomerSpendings cs
    GROUP BY cs."ArtistId"
)
SELECT
    ROUND(
        ABS(
            (SELECT "AvgSpending" FROM AverageSpendings WHERE "ArtistId" = (SELECT "ArtistId" FROM TopArtist))
            -
            (SELECT "AvgSpending" FROM AverageSpendings WHERE "ArtistId" = (SELECT "ArtistId" FROM LowestArtist))
        ),
        2
    ) AS "difference";