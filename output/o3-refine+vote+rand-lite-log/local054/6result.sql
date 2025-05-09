WITH artist_sales AS (
    SELECT ar."ArtistId",
           SUM(ii."UnitPrice" * ii."Quantity") AS total_sales
    FROM "invoice_items" ii
    JOIN "tracks"  t  ON t."TrackId"  = ii."TrackId"
    JOIN "albums"  al ON al."AlbumId" = t."AlbumId"
    JOIN "artists" ar ON ar."ArtistId" = al."ArtistId"
    GROUP BY ar."ArtistId"
),
best_artist AS (
    SELECT "ArtistId"
    FROM artist_sales
    ORDER BY total_sales DESC
    LIMIT 1
),
customer_spending AS (
    SELECT c."CustomerId",
           c."FirstName",
           SUM(ii."UnitPrice" * ii."Quantity") AS amount_spent
    FROM best_artist ba
    JOIN "albums"  al ON al."ArtistId" = ba."ArtistId"
    JOIN "tracks"  t  ON t."AlbumId"  = al."AlbumId"
    JOIN "invoice_items" ii ON ii."TrackId" = t."TrackId"
    JOIN "invoices" i  ON i."InvoiceId" = ii."InvoiceId"
    JOIN "customers" c ON c."CustomerId" = i."CustomerId"
    GROUP BY c."CustomerId"
)
SELECT cs."FirstName",
       ROUND(cs.amount_spent, 2) AS AmountSpent
FROM customer_spending cs
WHERE cs.amount_spent < 1
ORDER BY AmountSpent, cs."FirstName";