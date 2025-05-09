WITH sales_by_artist AS (
    SELECT
        ar."ArtistId",
        SUM(ii."UnitPrice" * ii."Quantity") AS total_sales
    FROM CHINOOK.CHINOOK.INVOICE_ITEMS   ii
    JOIN CHINOOK.CHINOOK.TRACKS          t   ON ii."TrackId"  = t."TrackId"
    JOIN CHINOOK.CHINOOK.ALBUMS          al  ON t."AlbumId"   = al."AlbumId"
    JOIN CHINOOK.CHINOOK.ARTISTS         ar  ON al."ArtistId" = ar."ArtistId"
    GROUP BY ar."ArtistId"
),
best_artist AS (                       -- artist with the highest total sales
    SELECT "ArtistId"
    FROM   sales_by_artist
    ORDER BY total_sales DESC NULLS LAST
    LIMIT 1
),
customer_spending AS (                 -- money each customer spent on that artist
    SELECT
        inv."CustomerId",
        SUM(ii."UnitPrice" * ii."Quantity") AS amount_spent
    FROM CHINOOK.CHINOOK.INVOICE_ITEMS  ii
    JOIN CHINOOK.CHINOOK.INVOICES       inv ON ii."InvoiceId" = inv."InvoiceId"
    JOIN CHINOOK.CHINOOK.TRACKS         t   ON ii."TrackId"   = t."TrackId"
    JOIN CHINOOK.CHINOOK.ALBUMS         al  ON t."AlbumId"    = al."AlbumId"
    JOIN best_artist                    ba  ON al."ArtistId"  = ba."ArtistId"
    GROUP BY inv."CustomerId"
)
SELECT
    c."FirstName",
    ROUND(cs.amount_spent, 4) AS "AmountSpent"
FROM customer_spending cs
JOIN CHINOOK.CHINOOK.CUSTOMERS c
  ON cs."CustomerId" = c."CustomerId"
WHERE cs.amount_spent < 1
ORDER BY cs.amount_spent ASC NULLS LAST;