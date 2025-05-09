WITH artist_totals AS (                -- total sales per artist
    SELECT ar."ArtistId",
           ar."Name",
           SUM(ii."UnitPrice" * ii."Quantity") AS total_sales
    FROM invoice_items  AS ii
    JOIN tracks         AS t  ON t."TrackId"  = ii."TrackId"
    JOIN albums         AS al ON al."AlbumId" = t."AlbumId"
    JOIN artists        AS ar ON ar."ArtistId"= al."ArtistId"
    GROUP BY ar."ArtistId", ar."Name"
),
top_artist AS (                        -- highest-selling artist (tie → name)
    SELECT "ArtistId" AS id
    FROM artist_totals
    ORDER BY total_sales DESC, "Name" ASC
    LIMIT 1
),
low_artist AS (                        -- lowest non-zero selling artist (tie → name)
    SELECT "ArtistId" AS id
    FROM artist_totals
    WHERE total_sales > 0
    ORDER BY total_sales ASC, "Name" ASC
    LIMIT 1
),
customer_spending AS (                 -- what each customer spent on each artist
    SELECT inv."CustomerId",
           al."ArtistId",
           SUM(ii."UnitPrice" * ii."Quantity") AS spent
    FROM invoice_items AS ii
    JOIN invoices      AS inv ON inv."InvoiceId" = ii."InvoiceId"
    JOIN tracks        AS t   ON t."TrackId"     = ii."TrackId"
    JOIN albums        AS al  ON al."AlbumId"    = t."AlbumId"
    GROUP BY inv."CustomerId", al."ArtistId"
),
avg_spending AS (                      -- average spend per artist across customers
    SELECT (SELECT AVG(spent)
            FROM customer_spending
            WHERE "ArtistId" = (SELECT id FROM top_artist)) AS avg_top,
           (SELECT AVG(spent)
            FROM customer_spending
            WHERE "ArtistId" = (SELECT id FROM low_artist)) AS avg_low
)
SELECT ABS(avg_top - avg_low) AS absolute_difference
FROM avg_spending;