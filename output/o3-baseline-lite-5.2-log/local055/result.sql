WITH artist_revenue AS (
    SELECT 
        ar."ArtistId",
        ar."Name",
        SUM(ii."UnitPrice" * ii."Quantity") AS revenue
    FROM artists            ar
    JOIN albums             al ON al."ArtistId" = ar."ArtistId"
    JOIN tracks             t  ON t."AlbumId"   = al."AlbumId"
    JOIN invoice_items      ii ON ii."TrackId"  = t."TrackId"
    GROUP BY ar."ArtistId", ar."Name"
),
top_artist AS (                -- highest–selling artist (tie → alphabetical)
    SELECT "ArtistId","Name"
    FROM artist_revenue
    WHERE revenue = (SELECT MAX(revenue) FROM artist_revenue)
    ORDER BY "Name"
    LIMIT 1
),
bottom_artist AS (             -- lowest–selling artist (tie → alphabetical)
    SELECT "ArtistId","Name"
    FROM artist_revenue
    WHERE revenue = (SELECT MIN(revenue) FROM artist_revenue)
    ORDER BY "Name"
    LIMIT 1
),
target_artists AS (            -- mark them as top / bottom
    SELECT "ArtistId", 'top'    AS artist_type FROM top_artist
    UNION ALL
    SELECT "ArtistId", 'bottom' AS artist_type FROM bottom_artist
),
customer_spending AS (         -- what each customer spent on each target artist
    SELECT
        inv."CustomerId",
        ta.artist_type,
        SUM(ii."UnitPrice" * ii."Quantity") AS spent
    FROM target_artists  ta
    JOIN albums          al  ON al."ArtistId" = ta."ArtistId"
    JOIN tracks          t   ON t."AlbumId"   = al."AlbumId"
    JOIN invoice_items   ii  ON ii."TrackId"  = t."TrackId"
    JOIN invoices        inv ON inv."InvoiceId" = ii."InvoiceId"
    GROUP BY inv."CustomerId", ta.artist_type
),
avg_spending AS (              -- average spending per artist‑type (only purchasers)
    SELECT artist_type, AVG(spent) AS avg_spent
    FROM customer_spending
    GROUP BY artist_type
)
SELECT
    ROUND(
        ABS( (SELECT avg_spent FROM avg_spending WHERE artist_type = 'top')
           - (SELECT avg_spent FROM avg_spending WHERE artist_type = 'bottom') )
        , 4
    ) AS avg_spending_difference;