WITH artist_sales AS (
    SELECT
        ar."ArtistId"                           AS artist_id,
        ar."Name"                              AS artist_name,
        SUM(ii."Quantity" * ii."UnitPrice")    AS total_sales
    FROM CHINOOK.CHINOOK."INVOICE_ITEMS"  ii
    JOIN CHINOOK.CHINOOK."TRACKS"         t  ON t."TrackId"   = ii."TrackId"
    JOIN CHINOOK.CHINOOK."ALBUMS"         al ON al."AlbumId"  = t."AlbumId"
    JOIN CHINOOK.CHINOOK."ARTISTS"        ar ON ar."ArtistId" = al."ArtistId"
    GROUP BY ar."ArtistId", ar."Name"
),
top_artist AS (      -- highest‐selling artist (alphabetical tie-break)
    SELECT artist_id, artist_name
    FROM artist_sales
    QUALIFY ROW_NUMBER() OVER (ORDER BY total_sales DESC NULLS LAST, artist_name ASC) = 1
),
bottom_artist AS (   -- lowest‐selling artist (alphabetical tie-break)
    SELECT artist_id, artist_name
    FROM artist_sales
    QUALIFY ROW_NUMBER() OVER (ORDER BY total_sales ASC NULLS LAST, artist_name ASC) = 1
),
selected_artists AS (
    SELECT artist_id, 'TOP'    AS artist_level FROM top_artist
    UNION ALL
    SELECT artist_id, 'BOTTOM' AS artist_level FROM bottom_artist
),
customer_spending AS (   -- how much each customer spent on the two artists
    SELECT
        inv."CustomerId",
        sa.artist_level,
        SUM(ii."Quantity" * ii."UnitPrice") AS spend
    FROM CHINOOK.CHINOOK."INVOICE_ITEMS"  ii
    JOIN CHINOOK.CHINOOK."INVOICES"       inv ON inv."InvoiceId" = ii."InvoiceId"
    JOIN CHINOOK.CHINOOK."TRACKS"         t   ON t."TrackId"     = ii."TrackId"
    JOIN CHINOOK.CHINOOK."ALBUMS"         al  ON al."AlbumId"    = t."AlbumId"
    JOIN CHINOOK.CHINOOK."ARTISTS"        ar  ON ar."ArtistId"   = al."ArtistId"
    JOIN selected_artists                 sa  ON sa.artist_id    = ar."ArtistId"
    GROUP BY inv."CustomerId", sa.artist_level
),
avg_spending AS (     -- average spend per customer for each artist level
    SELECT
        artist_level,
        AVG(spend) AS avg_spend
    FROM customer_spending
    GROUP BY artist_level
),
top_avg    AS (SELECT avg_spend FROM avg_spending WHERE artist_level = 'TOP'),
bottom_avg AS (SELECT avg_spend FROM avg_spending WHERE artist_level = 'BOTTOM')

SELECT
    ABS(t.avg_spend - b.avg_spend) AS "ABSOLUTE_DIFFERENCE"
FROM top_avg t
CROSS JOIN bottom_avg b;