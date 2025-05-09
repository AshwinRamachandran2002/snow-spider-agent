WITH ARTIST_SALES AS (
    SELECT
        al."ArtistId",
        SUM(ii."UnitPrice" * ii."Quantity") AS "TotalSales"
    FROM CHINOOK.CHINOOK.INVOICE_ITEMS  ii
    JOIN CHINOOK.CHINOOK.TRACKS        t  ON ii."TrackId" = t."TrackId"
    JOIN CHINOOK.CHINOOK.ALBUMS        al ON t."AlbumId"  = al."AlbumId"
    GROUP BY al."ArtistId"
),
BEST_ARTIST AS (           -- artist with the highest overall sales
    SELECT "ArtistId"
    FROM ARTIST_SALES
    ORDER BY "TotalSales" DESC NULLS LAST
    LIMIT 1
),
CUSTOMER_SPEND AS (        -- how much each customer spent on that artist
    SELECT
        c."CustomerId",
        c."FirstName",
        SUM(ii."UnitPrice" * ii."Quantity") AS "AmountSpent"
    FROM CHINOOK.CHINOOK.INVOICE_ITEMS ii
    JOIN CHINOOK.CHINOOK.INVOICES      i  ON ii."InvoiceId" = i."InvoiceId"
    JOIN CHINOOK.CHINOOK.TRACKS        t  ON ii."TrackId"  = t."TrackId"
    JOIN CHINOOK.CHINOOK.ALBUMS        al ON t."AlbumId"   = al."AlbumId"
    JOIN BEST_ARTIST                  ba ON al."ArtistId"  = ba."ArtistId"
    JOIN CHINOOK.CHINOOK.CUSTOMERS     c  ON i."CustomerId" = c."CustomerId"
    GROUP BY c."CustomerId", c."FirstName"
)
SELECT
    "FirstName",
    ROUND("AmountSpent", 4) AS "AmountSpent"
FROM CUSTOMER_SPEND
WHERE "AmountSpent" < 1          -- customers who spent less than $1
  AND "AmountSpent" > 0          -- exclude those with no purchases
ORDER BY "AmountSpent" ASC NULLS LAST, "FirstName";