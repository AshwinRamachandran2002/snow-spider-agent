WITH artist_sales AS (
    SELECT ar."ArtistId",
           SUM(ii."UnitPrice" * ii."Quantity") AS total_sales
    FROM "artists" ar
    JOIN "albums"  al ON al."ArtistId" = ar."ArtistId"
    JOIN "tracks"  t  ON t."AlbumId"   = al."AlbumId"
    JOIN "invoice_items" ii ON ii."TrackId" = t."TrackId"
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
    FROM "customers" c
    JOIN "invoices" i        ON i."CustomerId" = c."CustomerId"
    JOIN "invoice_items" ii  ON ii."InvoiceId"  = i."InvoiceId"
    JOIN "tracks" t          ON t."TrackId"     = ii."TrackId"
    JOIN "albums" al         ON al."AlbumId"    = t."AlbumId"
    WHERE al."ArtistId" = (SELECT "ArtistId" FROM best_artist)
    GROUP BY c."CustomerId", c."FirstName"
)
SELECT "FirstName",
       ROUND(amount_spent, 2) AS amount_spent
FROM customer_spending
WHERE amount_spent > 0
  AND amount_spent < 1
ORDER BY amount_spent, "FirstName";