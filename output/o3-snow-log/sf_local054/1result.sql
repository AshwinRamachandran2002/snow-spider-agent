WITH "ArtistRevenue" AS (
    SELECT
        ar."ArtistId",
        SUM(ii."UnitPrice" * ii."Quantity") AS "Revenue"
    FROM CHINOOK.CHINOOK.INVOICE_ITEMS      ii
    JOIN CHINOOK.CHINOOK.TRACKS             t  ON t."TrackId"  = ii."TrackId"
    JOIN CHINOOK.CHINOOK.ALBUMS             al ON al."AlbumId" = t."AlbumId"
    JOIN CHINOOK.CHINOOK.ARTISTS            ar ON ar."ArtistId" = al."ArtistId"
    GROUP BY ar."ArtistId"
),
"BestArtist" AS (
    SELECT "ArtistId"
    FROM "ArtistRevenue"
    ORDER BY "Revenue" DESC NULLS LAST
    LIMIT 1
),
"CustomerSpend" AS (
    SELECT
        c."CustomerId",
        c."FirstName",
        SUM(ii."UnitPrice" * ii."Quantity") AS "AmountSpent"
    FROM CHINOOK.CHINOOK.CUSTOMERS      c
    JOIN CHINOOK.CHINOOK.INVOICES       i  ON i."CustomerId" = c."CustomerId"
    JOIN CHINOOK.CHINOOK.INVOICE_ITEMS  ii ON ii."InvoiceId"  = i."InvoiceId"
    JOIN CHINOOK.CHINOOK.TRACKS         t  ON t."TrackId"     = ii."TrackId"
    JOIN CHINOOK.CHINOOK.ALBUMS         al ON al."AlbumId"    = t."AlbumId"
    JOIN "BestArtist"                   ba ON ba."ArtistId"   = al."ArtistId"
    GROUP BY c."CustomerId", c."FirstName"
)
SELECT
    "FirstName",
    ROUND("AmountSpent", 4) AS "AmountSpent"
FROM "CustomerSpend"
WHERE "AmountSpent" < 1
ORDER BY "AmountSpent" ASC, "FirstName";