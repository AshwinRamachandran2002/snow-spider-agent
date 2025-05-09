WITH artist_sales AS (          -- total revenue per artist
    SELECT ar."ArtistId",
           ar."Name",
           SUM(ii."UnitPrice"*ii."Quantity") AS revenue
    FROM   "invoice_items"  AS ii
    JOIN   "tracks"         AS t  ON t."TrackId"  = ii."TrackId"
    JOIN   "albums"         AS al ON al."AlbumId" = t."AlbumId"
    JOIN   "artists"        AS ar ON ar."ArtistId" = al."ArtistId"
    GROUP  BY ar."ArtistId", ar."Name"
),
top_artist AS (                 -- highest‑selling artist (alpha tie‑break)
    SELECT "ArtistId"
    FROM   artist_sales
    ORDER  BY revenue DESC, "Name"
    LIMIT  1
),
bottom_artist AS (              -- lowest‑selling artist (alpha tie‑break)
    SELECT "ArtistId"
    FROM   artist_sales
    ORDER  BY revenue ASC, "Name"
    LIMIT  1
),
top_customer_spend AS (         -- spend per customer on the top artist
    SELECT inv."CustomerId",
           SUM(ii."UnitPrice"*ii."Quantity") AS spend
    FROM   "invoice_items"  AS ii
    JOIN   "tracks"         AS t   ON t."TrackId"  = ii."TrackId"
    JOIN   "albums"         AS al  ON al."AlbumId" = t."AlbumId"
    JOIN   "invoices"       AS inv ON inv."InvoiceId" = ii."InvoiceId"
    WHERE  al."ArtistId" = (SELECT "ArtistId" FROM top_artist)
    GROUP  BY inv."CustomerId"
),
bottom_customer_spend AS (      -- spend per customer on the bottom artist
    SELECT inv."CustomerId",
           SUM(ii."UnitPrice"*ii."Quantity") AS spend
    FROM   "invoice_items"  AS ii
    JOIN   "tracks"         AS t   ON t."TrackId"  = ii."TrackId"
    JOIN   "albums"         AS al  ON al."AlbumId" = t."AlbumId"
    JOIN   "invoices"       AS inv ON inv."InvoiceId" = ii."InvoiceId"
    WHERE  al."ArtistId" = (SELECT "ArtistId" FROM bottom_artist)
    GROUP  BY inv."CustomerId"
),
top_avg AS (                    -- average spend on the top artist
    SELECT ROUND(AVG(spend),4) AS avg_top
    FROM   top_customer_spend
),
bottom_avg AS (                 -- average spend on the bottom artist
    SELECT ROUND(AVG(spend),4) AS avg_bottom
    FROM   bottom_customer_spend
)
SELECT ABS(top_avg.avg_top - bottom_avg.avg_bottom) AS "AvgSpendDifference"
FROM   top_avg, bottom_avg;