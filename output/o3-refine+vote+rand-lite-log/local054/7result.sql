WITH artist_sales AS (
    SELECT al."ArtistId",
           SUM(ii."UnitPrice" * ii."Quantity") AS total_sales
    FROM "invoice_items"  ii
    JOIN "tracks"         t  ON t."TrackId"  = ii."TrackId"
    JOIN "albums"         al ON al."AlbumId" = t."AlbumId"
    GROUP BY al."ArtistId"
),
best_artist AS (
    SELECT "ArtistId"
    FROM artist_sales
    WHERE total_sales = (SELECT MAX(total_sales) FROM artist_sales)
),
customer_spending AS (
    SELECT inv."CustomerId",
           SUM(ii."UnitPrice" * ii."Quantity") AS amount_spent
    FROM "invoice_items" ii
    JOIN "invoices"      inv ON inv."InvoiceId" = ii."InvoiceId"
    JOIN "tracks"        t   ON t."TrackId"     = ii."TrackId"
    JOIN "albums"        al  ON al."AlbumId"    = t."AlbumId"
    WHERE al."ArtistId" IN (SELECT "ArtistId" FROM best_artist)
    GROUP BY inv."CustomerId"
)
SELECT c."FirstName",
       ROUND(cs.amount_spent, 2) AS AmountSpent
FROM customer_spending cs
JOIN "customers" c ON c."CustomerId" = cs."CustomerId"
WHERE cs.amount_spent < 1
ORDER BY c."FirstName";