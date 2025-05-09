WITH top_artist AS (
    SELECT ar."ArtistId"
    FROM "artists" ar
    JOIN "albums"  al ON al."ArtistId" = ar."ArtistId"
    JOIN "tracks"  t  ON t."AlbumId"   = al."AlbumId"
    JOIN "invoice_items" ii ON ii."TrackId" = t."TrackId"
    GROUP BY ar."ArtistId"
    ORDER BY SUM(ii."UnitPrice" * ii."Quantity") DESC
    LIMIT 1
),
customer_totals AS (
    SELECT cu."CustomerId",
           cu."FirstName",
           SUM(ii."UnitPrice" * ii."Quantity") AS amount_spent
    FROM "customers" cu
    JOIN "invoices"      inv ON inv."CustomerId" = cu."CustomerId"
    JOIN "invoice_items" ii  ON ii."InvoiceId"   = inv."InvoiceId"
    JOIN "tracks"        t   ON t."TrackId"      = ii."TrackId"
    JOIN "albums"        al  ON al."AlbumId"     = t."AlbumId"
    WHERE al."ArtistId" = (SELECT "ArtistId" FROM top_artist)
    GROUP BY cu."CustomerId"
)
SELECT "FirstName",
       ROUND(amount_spent, 2) AS "Amount_Spent"
FROM customer_totals
WHERE amount_spent < 1
ORDER BY amount_spent;