WITH artist_sales AS (
    SELECT
        a."ArtistId",
        SUM(ii."UnitPrice" * ii."Quantity") AS total_sales
    FROM CHINOOK.CHINOOK.INVOICE_ITEMS           AS ii
    JOIN CHINOOK.CHINOOK.TRACKS                  AS t  ON ii."TrackId" = t."TrackId"
    JOIN CHINOOK.CHINOOK.ALBUMS                  AS a  ON t."AlbumId" = a."AlbumId"
    GROUP BY a."ArtistId"
),
best_artist AS (
    SELECT "ArtistId"
    FROM artist_sales
    ORDER BY total_sales DESC NULLS LAST
    LIMIT 1
),
customer_spent AS (
    SELECT
        inv."CustomerId",
        SUM(ii."UnitPrice" * ii."Quantity") AS amount_spent
    FROM CHINOOK.CHINOOK.INVOICE_ITEMS  AS ii
    JOIN CHINOOK.CHINOOK.INVOICES       AS inv ON ii."InvoiceId" = inv."InvoiceId"
    JOIN CHINOOK.CHINOOK.TRACKS         AS t   ON ii."TrackId"   = t."TrackId"
    JOIN CHINOOK.CHINOOK.ALBUMS         AS a   ON t."AlbumId"    = a."AlbumId"
    WHERE a."ArtistId" IN (SELECT "ArtistId" FROM best_artist)
    GROUP BY inv."CustomerId"
)
SELECT
    c."FirstName",
    cs.amount_spent
FROM customer_spent           AS cs
JOIN CHINOOK.CHINOOK.CUSTOMERS AS c ON cs."CustomerId" = c."CustomerId"
WHERE cs.amount_spent < 1
ORDER BY cs.amount_spent ASC NULLS LAST, c."FirstName";