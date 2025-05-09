WITH ArtistRevenue AS (
    SELECT ar."ArtistId",
           SUM(ii."UnitPrice" * ii."Quantity") AS total_revenue
    FROM artists ar
    JOIN albums  al ON al."ArtistId" = ar."ArtistId"
    JOIN tracks  t  ON t."AlbumId"   = al."AlbumId"
    JOIN invoice_items ii ON ii."TrackId" = t."TrackId"
    GROUP BY ar."ArtistId"
),
BestArtist AS (
    SELECT "ArtistId"
    FROM ArtistRevenue
    ORDER BY total_revenue DESC
    LIMIT 1
),
CustomerSpend AS (
    SELECT c."FirstName" AS first_name,
           SUM(ii."UnitPrice" * ii."Quantity") AS amount_spent
    FROM customers c
    JOIN invoices i       ON i."CustomerId" = c."CustomerId"
    JOIN invoice_items ii ON ii."InvoiceId" = i."InvoiceId"
    JOIN tracks t         ON t."TrackId"    = ii."TrackId"
    JOIN albums al        ON al."AlbumId"   = t."AlbumId"
    WHERE al."ArtistId" = (SELECT "ArtistId" FROM BestArtist)
    GROUP BY c."CustomerId"
)
SELECT first_name,
       printf('%.4f', amount_spent) AS amount_spent
FROM CustomerSpend
WHERE amount_spent < 1
ORDER BY amount_spent DESC, first_name;