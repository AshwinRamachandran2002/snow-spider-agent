WITH artist_sales AS (
    SELECT
        ar."ArtistId",
        SUM(ii."UnitPrice" * ii."Quantity") AS total_sales
    FROM CHINOOK.CHINOOK.ARTISTS          ar
    JOIN CHINOOK.CHINOOK.ALBUMS           al  ON al."ArtistId" = ar."ArtistId"
    JOIN CHINOOK.CHINOOK.TRACKS           t   ON t."AlbumId"   = al."AlbumId"
    JOIN CHINOOK.CHINOOK.INVOICE_ITEMS    ii  ON ii."TrackId"  = t."TrackId"
    GROUP BY ar."ArtistId"
), best_selling_artist AS (
    SELECT  "ArtistId"
    FROM    artist_sales
    QUALIFY ROW_NUMBER() OVER (ORDER BY total_sales DESC NULLS LAST) = 1
), customer_spending AS (
    SELECT
        c."CustomerId",
        c."FirstName",
        SUM(ii."UnitPrice" * ii."Quantity") AS amount_spent
    FROM CHINOOK.CHINOOK.CUSTOMERS       c
    JOIN CHINOOK.CHINOOK.INVOICES        i   ON i."CustomerId" = c."CustomerId"
    JOIN CHINOOK.CHINOOK.INVOICE_ITEMS   ii  ON ii."InvoiceId" = i."InvoiceId"
    JOIN CHINOOK.CHINOOK.TRACKS          t   ON t."TrackId"    = ii."TrackId"
    JOIN CHINOOK.CHINOOK.ALBUMS          al  ON al."AlbumId"   = t."AlbumId"
    JOIN best_selling_artist             bsa ON bsa."ArtistId" = al."ArtistId"
    GROUP BY c."CustomerId", c."FirstName"
)
SELECT
    "FirstName",
    ROUND(amount_spent, 4) AS amount_spent
FROM customer_spending
WHERE amount_spent < 1
ORDER BY amount_spent ASC NULLS LAST;