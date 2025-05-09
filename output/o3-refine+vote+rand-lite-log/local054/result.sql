WITH artist_sales AS (
    SELECT ar."ArtistId",
           SUM(ii."UnitPrice" * ii."Quantity") AS total_sales
    FROM "artists" ar
    JOIN "albums"  al ON al."ArtistId" = ar."ArtistId"
    JOIN "tracks"  t  ON t."AlbumId"  = al."AlbumId"
    JOIN "invoice_items" ii ON ii."TrackId" = t."TrackId"
    GROUP BY ar."ArtistId"
),
best_artist AS (
    SELECT "ArtistId"
    FROM artist_sales
    ORDER BY total_sales DESC, "ArtistId" ASC
    LIMIT 1
),
customer_spend AS (
    SELECT c."CustomerId",
           c."FirstName",
           SUM(ii."UnitPrice" * ii."Quantity") AS amount_spent
    FROM "customers" c
    JOIN "invoices" i        ON i."CustomerId" = c."CustomerId"
    JOIN "invoice_items" ii  ON ii."InvoiceId" = i."InvoiceId"
    JOIN "tracks" t          ON t."TrackId"    = ii."TrackId"
    JOIN "albums" al         ON al."AlbumId"   = t."AlbumId"
    WHERE al."ArtistId" = (SELECT "ArtistId" FROM best_artist)
    GROUP BY c."CustomerId"
)
SELECT "FirstName",
       ROUND(amount_spent, 4) AS AmountSpent
FROM customer_spend
WHERE amount_spent < 1
ORDER BY "FirstName";