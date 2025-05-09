WITH artist_sales AS (          -- total sales for every artist
    SELECT ar."ArtistId",
           ar."Name",
           SUM(ii."UnitPrice" * ii."Quantity") AS total_sales
    FROM "invoice_items" AS ii
    JOIN "tracks"  AS t  ON t."TrackId"  = ii."TrackId"
    JOIN "albums"  AS al ON al."AlbumId" = t."AlbumId"
    JOIN "artists" AS ar ON ar."ArtistId"= al."ArtistId"
    GROUP BY ar."ArtistId", ar."Name"
),
top_artist AS (                 -- highest-selling artist (tie → alphabetical)
    SELECT "ArtistId"
    FROM   artist_sales
    ORDER BY total_sales DESC, "Name" ASC
    LIMIT 1
),
bottom_artist AS (              -- lowest-selling artist (tie → alphabetical)
    SELECT "ArtistId"
    FROM   artist_sales
    ORDER BY total_sales ASC,  "Name" ASC
    LIMIT 1
),
customer_spend AS (             -- what each customer spent on those two artists
    SELECT inv."CustomerId",
           ar."ArtistId",
           SUM(ii."UnitPrice" * ii."Quantity") AS spend
    FROM "invoice_items" AS ii
    JOIN "invoices"  AS inv ON inv."InvoiceId" = ii."InvoiceId"
    JOIN "tracks"    AS t   ON t."TrackId"     = ii."TrackId"
    JOIN "albums"    AS al  ON al."AlbumId"    = t."AlbumId"
    JOIN "artists"   AS ar  ON ar."ArtistId"   = al."ArtistId"
    WHERE ar."ArtistId" IN (SELECT "ArtistId" FROM top_artist
                            UNION ALL
                            SELECT "ArtistId" FROM bottom_artist)
    GROUP BY inv."CustomerId", ar."ArtistId"
),
avg_spend AS (                  -- average spend per artist across relevant customers
    SELECT AVG(CASE WHEN "ArtistId" = (SELECT "ArtistId" FROM top_artist)
                    THEN spend END)  AS avg_top,
           AVG(CASE WHEN "ArtistId" = (SELECT "ArtistId" FROM bottom_artist)
                    THEN spend END)  AS avg_bottom
    FROM customer_spend
)
SELECT ROUND(ABS(avg_top - avg_bottom), 4) AS "AbsoluteDifferenceInAverages"
FROM   avg_spend;