WITH artist_sales AS (
    SELECT
        ar."ArtistId",
        SUM(ii."UnitPrice" * ii."Quantity") AS total_sales
    FROM CHINOOK.CHINOOK.INVOICE_ITEMS   ii
    JOIN CHINOOK.CHINOOK.TRACKS          t  ON t."TrackId"  = ii."TrackId"
    JOIN CHINOOK.CHINOOK.ALBUMS          al ON al."AlbumId" = t."AlbumId"
    JOIN CHINOOK.CHINOOK.ARTISTS         ar ON ar."ArtistId"= al."ArtistId"
    GROUP BY ar."ArtistId"
),
best_artist AS (      -- single-row CTE holding the best-selling artist
    SELECT "ArtistId"
    FROM artist_sales
    ORDER BY total_sales DESC NULLS LAST
    LIMIT 1
),
customer_spend AS (
    SELECT
        c."CustomerId",
        c."FirstName",
        SUM(ii."UnitPrice" * ii."Quantity") AS amount_spent
    FROM CHINOOK.CHINOOK.CUSTOMERS       c
    JOIN CHINOOK.CHINOOK.INVOICES        inv ON inv."CustomerId" = c."CustomerId"
    JOIN CHINOOK.CHINOOK.INVOICE_ITEMS   ii  ON ii."InvoiceId"   = inv."InvoiceId"
    JOIN CHINOOK.CHINOOK.TRACKS          t   ON t."TrackId"      = ii."TrackId"
    JOIN CHINOOK.CHINOOK.ALBUMS          al  ON al."AlbumId"     = t."AlbumId"
    JOIN best_artist                     ba  ON ba."ArtistId"    = al."ArtistId"
    GROUP BY c."CustomerId", c."FirstName"
)
SELECT
    "FirstName",
    ROUND(amount_spent, 4) AS amount_spent
FROM customer_spend
WHERE amount_spent < 1
ORDER BY amount_spent ASC NULLS LAST;