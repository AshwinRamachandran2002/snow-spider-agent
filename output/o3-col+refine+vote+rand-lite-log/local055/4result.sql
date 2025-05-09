WITH artist_sales AS (
    SELECT ar."ArtistId",
           ar."Name",
           SUM(ii."UnitPrice" * ii."Quantity") AS total_sales
    FROM "artists"        ar
    JOIN "albums"         al  ON ar."ArtistId" = al."ArtistId"
    JOIN "tracks"         t   ON al."AlbumId"  = t."AlbumId"
    JOIN "invoice_items"  ii  ON t."TrackId"   = ii."TrackId"
    GROUP BY ar."ArtistId", ar."Name"
),
top_artist AS (           -- highest-selling (tie-break by name)
    SELECT "ArtistId"
    FROM artist_sales
    ORDER BY total_sales DESC, "Name" ASC
    LIMIT 1
),
bottom_artist AS (        -- lowest-selling (tie-break by name)
    SELECT "ArtistId"
    FROM artist_sales
    ORDER BY total_sales ASC, "Name" ASC
    LIMIT 1
),
top_spend AS (            -- what each customer spent on the top artist
    SELECT inv."CustomerId",
           SUM(ii."UnitPrice" * ii."Quantity") AS spend
    FROM top_artist       ta
    JOIN "albums"         al  ON ta."ArtistId" = al."ArtistId"
    JOIN "tracks"         t   ON al."AlbumId"  = t."AlbumId"
    JOIN "invoice_items"  ii  ON t."TrackId"   = ii."TrackId"
    JOIN "invoices"       inv ON ii."InvoiceId" = inv."InvoiceId"
    GROUP BY inv."CustomerId"
),
bottom_spend AS (         -- what each customer spent on the bottom artist
    SELECT inv."CustomerId",
           SUM(ii."UnitPrice" * ii."Quantity") AS spend
    FROM bottom_artist    ba
    JOIN "albums"         al  ON ba."ArtistId" = al."ArtistId"
    JOIN "tracks"         t   ON al."AlbumId"  = t."AlbumId"
    JOIN "invoice_items"  ii  ON t."TrackId"   = ii."TrackId"
    JOIN "invoices"       inv ON ii."InvoiceId" = inv."InvoiceId"
    GROUP BY inv."CustomerId"
),
averages AS (
    SELECT (SELECT AVG(spend) FROM top_spend)    AS avg_top,
           (SELECT AVG(spend) FROM bottom_spend) AS avg_bottom
)
SELECT ROUND(ABS(avg_top - avg_bottom), 4) AS "Absolute_Difference"
FROM averages;