WITH
BestSellingArtist AS (
    SELECT "ArtistId"
    FROM (
        SELECT a."ArtistId", a."Name", SUM(ii."UnitPrice" * ii."Quantity") AS "TotalSales"
        FROM "CHINOOK"."CHINOOK"."INVOICE_ITEMS" ii
        INNER JOIN "CHINOOK"."CHINOOK"."TRACKS" t ON ii."TrackId" = t."TrackId"
        INNER JOIN "CHINOOK"."CHINOOK"."ALBUMS" al ON t."AlbumId" = al."AlbumId"
        INNER JOIN "CHINOOK"."CHINOOK"."ARTISTS" a ON al."ArtistId" = a."ArtistId"
        GROUP BY a."ArtistId", a."Name"
    ) AS artist_sales
    ORDER BY "TotalSales" DESC NULLS LAST, "Name" ASC
    LIMIT 1
),
LeastSellingArtist AS (
    SELECT "ArtistId"
    FROM (
        SELECT a."ArtistId", a."Name", SUM(ii."UnitPrice" * ii."Quantity") AS "TotalSales"
        FROM "CHINOOK"."CHINOOK"."INVOICE_ITEMS" ii
        INNER JOIN "CHINOOK"."CHINOOK"."TRACKS" t ON ii."TrackId" = t."TrackId"
        INNER JOIN "CHINOOK"."CHINOOK"."ALBUMS" al ON t."AlbumId" = al."AlbumId"
        INNER JOIN "CHINOOK"."CHINOOK"."ARTISTS" a ON al."ArtistId" = a."ArtistId"
        GROUP BY a."ArtistId", a."Name"
    ) AS artist_sales
    ORDER BY "TotalSales" ASC NULLS LAST, "Name" ASC
    LIMIT 1
),
AvgSpendingBest AS (
    SELECT AVG(cust_total."TotalSpent") AS "AvgSpending"
    FROM (
        SELECT c."CustomerId", SUM(i."Total") AS "TotalSpent"
        FROM "CHINOOK"."CHINOOK"."CUSTOMERS" c
        INNER JOIN "CHINOOK"."CHINOOK"."INVOICES" i ON c."CustomerId" = i."CustomerId"
        WHERE c."CustomerId" IN (
            SELECT DISTINCT c_b."CustomerId"
            FROM "CHINOOK"."CHINOOK"."CUSTOMERS" c_b
            INNER JOIN "CHINOOK"."CHINOOK"."INVOICES" i_b ON c_b."CustomerId" = i_b."CustomerId"
            INNER JOIN "CHINOOK"."CHINOOK"."INVOICE_ITEMS" ii_b ON i_b."InvoiceId" = ii_b."InvoiceId"
            INNER JOIN "CHINOOK"."CHINOOK"."TRACKS" t_b ON ii_b."TrackId" = t_b."TrackId"
            INNER JOIN "CHINOOK"."CHINOOK"."ALBUMS" al_b ON t_b."AlbumId" = al_b."AlbumId"
            WHERE al_b."ArtistId" = (SELECT "ArtistId" FROM BestSellingArtist)
        )
        GROUP BY c."CustomerId"
    ) AS cust_total
),
AvgSpendingLeast AS (
    SELECT AVG(cust_total."TotalSpent") AS "AvgSpending"
    FROM (
        SELECT c."CustomerId", SUM(i."Total") AS "TotalSpent"
        FROM "CHINOOK"."CHINOOK"."CUSTOMERS" c
        INNER JOIN "CHINOOK"."CHINOOK"."INVOICES" i ON c."CustomerId" = i."CustomerId"
        WHERE c."CustomerId" IN (
            SELECT DISTINCT c_l."CustomerId"
            FROM "CHINOOK"."CHINOOK"."CUSTOMERS" c_l
            INNER JOIN "CHINOOK"."CHINOOK"."INVOICES" i_l ON c_l."CustomerId" = i_l."CustomerId"
            INNER JOIN "CHINOOK"."CHINOOK"."INVOICE_ITEMS" ii_l ON i_l."InvoiceId" = ii_l."InvoiceId"
            INNER JOIN "CHINOOK"."CHINOOK"."TRACKS" t_l ON ii_l."TrackId" = t_l."TrackId"
            INNER JOIN "CHINOOK"."CHINOOK"."ALBUMS" al_l ON t_l."AlbumId" = al_l."AlbumId"
            WHERE al_l."ArtistId" = (SELECT "ArtistId" FROM LeastSellingArtist)
        )
        GROUP BY c."CustomerId"
    ) AS cust_total
)
SELECT
    ROUND(ABS((SELECT "AvgSpending" FROM AvgSpendingBest) - (SELECT "AvgSpending" FROM AvgSpendingLeast)), 4) AS "Difference in average spending";