WITH artist_totals AS (
    SELECT ar."ArtistId",
           ar."Name",
           SUM(ii."UnitPrice" * ii."Quantity") AS total_sales
    FROM   "invoice_items" AS ii
    JOIN   "tracks"        AS t  ON ii."TrackId" = t."TrackId"
    JOIN   "albums"        AS al ON t."AlbumId" = al."AlbumId"
    JOIN   "artists"       AS ar ON al."ArtistId" = ar."ArtistId"
    GROUP  BY ar."ArtistId", ar."Name"
),
top_artist AS (
    SELECT "ArtistId" AS artist_id
    FROM   artist_totals
    ORDER  BY total_sales DESC, "Name" ASC
    LIMIT 1
),
bottom_artist AS (
    SELECT "ArtistId" AS artist_id
    FROM   artist_totals
    ORDER  BY total_sales ASC, "Name" ASC
    LIMIT 1
),
customer_spend AS (
    SELECT inv."CustomerId",
           ar."ArtistId",
           SUM(ii."UnitPrice" * ii."Quantity") AS spend
    FROM   "invoice_items" AS ii
    JOIN   "tracks"        AS t  ON ii."TrackId" = t."TrackId"
    JOIN   "albums"        AS al ON t."AlbumId" = al."AlbumId"
    JOIN   "artists"       AS ar ON al."ArtistId" = ar."ArtistId"
    JOIN   "invoices"      AS inv ON ii."InvoiceId" = inv."InvoiceId"
    WHERE  ar."ArtistId" IN (SELECT artist_id FROM top_artist
                             UNION ALL
                             SELECT artist_id FROM bottom_artist)
    GROUP  BY inv."CustomerId", ar."ArtistId"
),
avg_top AS (
    SELECT AVG(spend) AS val
    FROM   customer_spend
    WHERE  "ArtistId" = (SELECT artist_id FROM top_artist)
),
avg_bottom AS (
    SELECT AVG(spend) AS val
    FROM   customer_spend
    WHERE  "ArtistId" = (SELECT artist_id FROM bottom_artist)
)
SELECT ROUND(
         ABS((SELECT val FROM avg_top) - (SELECT val FROM avg_bottom))
       , 4) AS average_spend_difference;