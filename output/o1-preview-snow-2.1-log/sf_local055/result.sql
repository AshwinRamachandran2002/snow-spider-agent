WITH
BestSellingArtist AS (
    SELECT
        ar."ArtistId" AS "BestArtistId",
        ar."Name" AS "BestArtistName"
    FROM
        CHINOOK.CHINOOK.INVOICE_ITEMS ii
    JOIN
        CHINOOK.CHINOOK.TRACKS t ON ii."TrackId" = t."TrackId"
    JOIN
        CHINOOK.CHINOOK.ALBUMS a ON t."AlbumId" = a."AlbumId"
    JOIN
        CHINOOK.CHINOOK.ARTISTS ar ON a."ArtistId" = ar."ArtistId"
    GROUP BY
        ar."ArtistId", ar."Name"
    ORDER BY
        COUNT(ii."InvoiceLineId") DESC NULLS LAST,
        ar."Name" ASC
    LIMIT 1
),
LeastSellingArtist AS (
    SELECT
        ar."ArtistId" AS "LeastArtistId",
        ar."Name" AS "LeastArtistName"
    FROM
        CHINOOK.CHINOOK.ARTISTS ar
    JOIN
        CHINOOK.CHINOOK.ALBUMS a ON ar."ArtistId" = a."ArtistId"
    JOIN
        CHINOOK.CHINOOK.TRACKS t ON a."AlbumId" = t."AlbumId"
    LEFT JOIN
        CHINOOK.CHINOOK.INVOICE_ITEMS ii ON t."TrackId" = ii."TrackId"
    GROUP BY
        ar."ArtistId", ar."Name"
    HAVING
        COUNT(ii."InvoiceLineId") > 0
    ORDER BY
        COUNT(ii."InvoiceLineId") ASC NULLS LAST,
        ar."Name" ASC
    LIMIT 1
),
BestCustomers AS (
    SELECT DISTINCT c."CustomerId"
    FROM
        BestSellingArtist bsa
    JOIN
        CHINOOK.CHINOOK.ALBUMS a ON bsa."BestArtistId" = a."ArtistId"
    JOIN
        CHINOOK.CHINOOK.TRACKS t ON a."AlbumId" = t."AlbumId"
    JOIN
        CHINOOK.CHINOOK.INVOICE_ITEMS ii ON t."TrackId" = ii."TrackId"
    JOIN
        CHINOOK.CHINOOK.INVOICES i ON ii."InvoiceId" = i."InvoiceId"
    JOIN
        CHINOOK.CHINOOK.CUSTOMERS c ON i."CustomerId" = c."CustomerId"
),
LeastCustomers AS (
    SELECT DISTINCT c."CustomerId"
    FROM
        LeastSellingArtist lsa
    JOIN
        CHINOOK.CHINOOK.ALBUMS a ON lsa."LeastArtistId" = a."ArtistId"
    JOIN
        CHINOOK.CHINOOK.TRACKS t ON a."AlbumId" = t."AlbumId"
    JOIN
        CHINOOK.CHINOOK.INVOICE_ITEMS ii ON t."TrackId" = ii."TrackId"
    JOIN
        CHINOOK.CHINOOK.INVOICES i ON ii."InvoiceId" = i."InvoiceId"
    JOIN
        CHINOOK.CHINOOK.CUSTOMERS c ON i."CustomerId" = c."CustomerId"
),
BestCustomerSpending AS (
    SELECT bc."CustomerId", SUM(i."Total") AS "TotalSpending"
    FROM
        BestCustomers bc
    JOIN
        CHINOOK.CHINOOK.INVOICES i ON bc."CustomerId" = i."CustomerId"
    GROUP BY bc."CustomerId"
),
LeastCustomerSpending AS (
    SELECT lc."CustomerId", SUM(i."Total") AS "TotalSpending"
    FROM
        LeastCustomers lc
    JOIN
        CHINOOK.CHINOOK.INVOICES i ON lc."CustomerId" = i."CustomerId"
    GROUP BY lc."CustomerId"
)
SELECT ROUND(ABS(
    (SELECT AVG("TotalSpending") FROM BestCustomerSpending) -
    (SELECT AVG("TotalSpending") FROM LeastCustomerSpending)
), 4) AS "DifferenceInAverageSpending";