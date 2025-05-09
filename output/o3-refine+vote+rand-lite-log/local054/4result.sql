WITH artist_sales AS (
    SELECT ar."ArtistId",
           SUM(ii."UnitPrice" * ii."Quantity") AS total_sales
    FROM "invoice_items"  ii
    JOIN "tracks"         t  ON t."TrackId"  = ii."TrackId"
    JOIN "albums"         al ON al."AlbumId" = t."AlbumId"
    JOIN "artists"        ar ON ar."ArtistId" = al."ArtistId"
    GROUP BY ar."ArtistId"
),
best_artist AS (                 -- artist with the highest sales
    SELECT "ArtistId"
    FROM artist_sales
    ORDER BY total_sales DESC
    LIMIT 1
),
customer_spend AS (              -- spending per customer on that artist
    SELECT c."CustomerId",
           c."FirstName",
           SUM(ii."UnitPrice" * ii."Quantity") AS spent
    FROM "invoice_items"  ii
    JOIN "invoices"       i  ON i."InvoiceId"  = ii."InvoiceId"
    JOIN "customers"      c  ON c."CustomerId" = i."CustomerId"
    JOIN "tracks"         t  ON t."TrackId"    = ii."TrackId"
    JOIN "albums"         al ON al."AlbumId"   = t."AlbumId"
    JOIN best_artist      ba ON ba."ArtistId"  = al."ArtistId"
    GROUP BY c."CustomerId", c."FirstName"
)
SELECT "FirstName",
       ROUND(spent, 4) AS amount_spent
FROM customer_spend
WHERE spent < 1
ORDER BY amount_spent, "FirstName";