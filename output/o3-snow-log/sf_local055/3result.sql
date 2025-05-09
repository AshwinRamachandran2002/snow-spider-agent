WITH artist_sales AS (   -- total revenue per artist (includes zero-sale artists)
    SELECT
        a."ArtistId",
        a."Name",
        COALESCE(SUM(ii."UnitPrice" * ii."Quantity"),0)      AS revenue
    FROM CHINOOK.CHINOOK.ARTISTS           a
    LEFT JOIN CHINOOK.CHINOOK.ALBUMS       al ON al."ArtistId" = a."ArtistId"
    LEFT JOIN CHINOOK.CHINOOK.TRACKS       t  ON t."AlbumId"  = al."AlbumId"
    LEFT JOIN CHINOOK.CHINOOK.INVOICE_ITEMS ii ON ii."TrackId" = t."TrackId"
    GROUP BY a."ArtistId", a."Name"
),

top_artist AS (          -- highest-selling artist  (ties → alpha order)
    SELECT "ArtistId","Name",revenue
    FROM   artist_sales
    QUALIFY ROW_NUMBER() OVER (ORDER BY revenue DESC, "Name" ASC) = 1
),

low_artist AS (          -- lowest-selling artist   (ties → alpha order)
    SELECT "ArtistId","Name",revenue
    FROM   artist_sales
    QUALIFY ROW_NUMBER() OVER (ORDER BY revenue ASC , "Name" ASC) = 1
),

target_artists AS (      -- two artists we care about
    SELECT 'TOP' AS artist_type, "ArtistId" FROM top_artist
    UNION ALL
    SELECT 'LOW'         , "ArtistId" FROM low_artist
),

customer_spending AS (   -- how much each customer spent on each of the two artists
    SELECT
        inv."CustomerId",
        ta.artist_type,
        SUM(ii."UnitPrice" * ii."Quantity") AS spending
    FROM target_artists           ta
    JOIN CHINOOK.CHINOOK.ALBUMS   al  ON al."ArtistId" = ta."ArtistId"
    JOIN CHINOOK.CHINOOK.TRACKS   t   ON t."AlbumId"  = al."AlbumId"
    JOIN CHINOOK.CHINOOK.INVOICE_ITEMS ii ON ii."TrackId" = t."TrackId"
    JOIN CHINOOK.CHINOOK.INVOICES inv     ON inv."InvoiceId" = ii."InvoiceId"
    GROUP BY inv."CustomerId", ta.artist_type
),

avg_spending AS (        -- average spend per artist type (only customers who bought that artist)
    SELECT artist_type, AVG(spending) AS avg_spent
    FROM   customer_spending
    GROUP BY artist_type
)

SELECT
    ABS( (SELECT avg_spent FROM avg_spending WHERE artist_type = 'TOP')
       - (SELECT avg_spent FROM avg_spending WHERE artist_type = 'LOW') ) AS "AVG_SPENDING_DIFF";