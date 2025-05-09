WITH artist_sales AS (
    SELECT ar."ArtistId",
           SUM(ii."UnitPrice" * ii."Quantity") AS revenue
    FROM invoice_items  ii
    JOIN tracks         t  ON t."TrackId"  = ii."TrackId"
    JOIN albums         al ON al."AlbumId" = t."AlbumId"
    JOIN artists        ar ON ar."ArtistId" = al."ArtistId"
    GROUP BY ar."ArtistId"
),
best_artist AS (
    SELECT "ArtistId"
    FROM artist_sales
    ORDER BY revenue DESC
    LIMIT 1
),
customer_spend AS (
    SELECT c."FirstName",
           SUM(ii."UnitPrice" * ii."Quantity") AS total_spent
    FROM best_artist   ba
    JOIN albums        al ON al."ArtistId" = ba."ArtistId"
    JOIN tracks        t  ON t."AlbumId"   = al."AlbumId"
    JOIN invoice_items ii ON ii."TrackId"  = t."TrackId"
    JOIN invoices      i  ON i."InvoiceId" = ii."InvoiceId"
    JOIN customers     c  ON c."CustomerId"= i."CustomerId"
    GROUP BY c."FirstName"
    HAVING total_spent < 1
)
SELECT "FirstName",
       ROUND(total_spent, 2) AS AmountSpent
FROM customer_spend
ORDER BY "FirstName";