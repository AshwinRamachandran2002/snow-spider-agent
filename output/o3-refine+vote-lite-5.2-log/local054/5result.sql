WITH ArtistSales AS (
    SELECT
        ar."ArtistId",
        SUM(ii."UnitPrice" * ii."Quantity") AS TotalSales
    FROM "artists" ar
    JOIN "albums"  al  ON al."ArtistId" = ar."ArtistId"
    JOIN "tracks"  t   ON t."AlbumId"   = al."AlbumId"
    JOIN "invoice_items" ii ON ii."TrackId" = t."TrackId"
    GROUP BY ar."ArtistId"
),
BestArtist AS (
    SELECT "ArtistId"
    FROM ArtistSales
    ORDER BY TotalSales DESC
    LIMIT 1
),
CustomerSpend AS (
    SELECT
        c."FirstName",
        SUM(ii."UnitPrice" * ii."Quantity") AS AmountSpent
    FROM BestArtist ba
    JOIN "albums"  al  ON al."ArtistId" = ba."ArtistId"
    JOIN "tracks"  t   ON t."AlbumId"   = al."AlbumId"
    JOIN "invoice_items" ii ON ii."TrackId" = t."TrackId"
    JOIN "invoices" inv     ON inv."InvoiceId" = ii."InvoiceId"
    JOIN "customers" c      ON c."CustomerId"  = inv."CustomerId"
    GROUP BY c."CustomerId"
)
SELECT
    "FirstName",
    ROUND(AmountSpent, 4) AS AmountSpent
FROM CustomerSpend
WHERE AmountSpent < 1
ORDER BY AmountSpent, "FirstName";