WITH artist_sales AS (       -- total revenue per artist
    SELECT
        a."ArtistId",
        a."Name",
        COALESCE(SUM(ii."UnitPrice" * ii."Quantity"),0) AS revenue
    FROM CHINOOK.CHINOOK."ARTISTS"          a
    LEFT JOIN CHINOOK.CHINOOK."ALBUMS"       al  ON al."ArtistId" = a."ArtistId"
    LEFT JOIN CHINOOK.CHINOOK."TRACKS"       t   ON t."AlbumId"   = al."AlbumId"
    LEFT JOIN CHINOOK.CHINOOK."INVOICE_ITEMS"ii  ON ii."TrackId"  = t."TrackId"
    GROUP BY a."ArtistId", a."Name"
),

-- best-selling and worst-selling artists (ties → alphabetical order)
top_artist AS (
    SELECT "ArtistId","Name"
    FROM artist_sales
    ORDER BY revenue DESC NULLS LAST, "Name" ASC
    LIMIT 1
),
low_artist AS (
    SELECT "ArtistId","Name"
    FROM artist_sales
    ORDER BY revenue ASC NULLS FIRST,  "Name" ASC
    LIMIT 1
),

chosen_artists AS (          -- the two artists we care about
    SELECT * FROM top_artist
    UNION ALL
    SELECT * FROM low_artist
),

-- how much each customer spent on the chosen artists
customer_spending AS (
    SELECT
        inv."CustomerId",
        art."ArtistId",
        SUM(ii."UnitPrice" * ii."Quantity") AS spend
    FROM CHINOOK.CHINOOK."INVOICE_ITEMS"  ii
    JOIN CHINOOK.CHINOOK."INVOICES"       inv ON inv."InvoiceId" = ii."InvoiceId"
    JOIN CHINOOK.CHINOOK."TRACKS"          tr ON tr."TrackId"    = ii."TrackId"
    JOIN CHINOOK.CHINOOK."ALBUMS"         alb ON alb."AlbumId"   = tr."AlbumId"
    JOIN CHINOOK.CHINOOK."ARTISTS"        art ON art."ArtistId"  = alb."ArtistId"
    JOIN chosen_artists                    ca ON ca."ArtistId"   = art."ArtistId"
    GROUP BY inv."CustomerId", art."ArtistId"
),

-- average spend for customers of each of the two artists
avg_spending AS (
    SELECT
        CASE
            WHEN "ArtistId" = (SELECT "ArtistId" FROM top_artist) THEN 'TOP'
            ELSE 'LOW'
        END                                   AS artist_type,
        AVG(spend)                            AS avg_spend
    FROM customer_spending
    GROUP BY artist_type
)

-- absolute difference between the two averages
SELECT ABS(
           (SELECT avg_spend FROM avg_spending WHERE artist_type = 'TOP')
         - (SELECT avg_spend FROM avg_spending WHERE artist_type = 'LOW')
       ) AS "ABSOLUTE_DIFFERENCE";