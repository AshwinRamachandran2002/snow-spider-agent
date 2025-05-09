WITH artist_sales AS (
    SELECT
        alb."ArtistId",
        SUM(ii."UnitPrice" * ii."Quantity") AS total_sales
    FROM CHINOOK.CHINOOK.INVOICE_ITEMS      AS ii
    JOIN CHINOOK.CHINOOK.TRACKS            AS t   ON ii."TrackId" = t."TrackId"
    JOIN CHINOOK.CHINOOK.ALBUMS            AS alb ON t."AlbumId" = alb."AlbumId"
    GROUP BY alb."ArtistId"
),
best_artist AS (
    SELECT "ArtistId"
    FROM artist_sales
    QUALIFY ROW_NUMBER() OVER (ORDER BY total_sales DESC NULLS LAST) = 1
),
customer_spend AS (
    SELECT
        inv."CustomerId",
        SUM(ii."UnitPrice" * ii."Quantity") AS amount_spent
    FROM CHINOOK.CHINOOK.INVOICE_ITEMS  AS ii
    JOIN CHINOOK.CHINOOK.INVOICES       AS inv ON ii."InvoiceId" = inv."InvoiceId"
    JOIN CHINOOK.CHINOOK.TRACKS         AS t   ON ii."TrackId" = t."TrackId"
    JOIN CHINOOK.CHINOOK.ALBUMS         AS alb ON t."AlbumId" = alb."AlbumId"
    JOIN best_artist                    AS ba  ON alb."ArtistId" = ba."ArtistId"
    GROUP BY inv."CustomerId"
)
SELECT
    c."FirstName",
    ROUND(cs.amount_spent, 4) AS "AmountSpent"
FROM customer_spend               AS cs
JOIN CHINOOK.CHINOOK.CUSTOMERS    AS c  ON cs."CustomerId" = c."CustomerId"
WHERE cs.amount_spent > 0
  AND cs.amount_spent < 1
ORDER BY cs.amount_spent ASC NULLS LAST;