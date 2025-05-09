WITH artist_sales AS (
    SELECT al."ArtistId",
           SUM(ii."UnitPrice" * ii."Quantity") AS total_sales
    FROM "albums"        al
    JOIN "tracks"        t   ON t."AlbumId"  = al."AlbumId"
    JOIN "invoice_items" ii  ON ii."TrackId" = t."TrackId"
    GROUP BY al."ArtistId"
),
best_artist AS (
    SELECT "ArtistId"
    FROM artist_sales
    ORDER BY total_sales DESC
    LIMIT 1
),
customer_spending AS (
    SELECT c."FirstName",
           SUM(ii."UnitPrice" * ii."Quantity") AS amount_spent
    FROM best_artist        ba
    JOIN "albums"        al ON al."ArtistId" = ba."ArtistId"
    JOIN "tracks"        t  ON t."AlbumId"   = al."AlbumId"
    JOIN "invoice_items" ii ON ii."TrackId"  = t."TrackId"
    JOIN "invoices"      inv ON inv."InvoiceId" = ii."InvoiceId"
    JOIN "customers"     c   ON c."CustomerId"  = inv."CustomerId"
    GROUP BY c."CustomerId"
)
SELECT "FirstName",
       ROUND(amount_spent, 2) AS AmountSpent
FROM customer_spending
WHERE amount_spent < 1
ORDER BY AmountSpent, "FirstName";