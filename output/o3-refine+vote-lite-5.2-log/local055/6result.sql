WITH artist_sales AS (
    SELECT ar.ArtistId,
           ar.Name,
           SUM(ii.UnitPrice * ii.Quantity) AS revenue
    FROM invoice_items  ii
    JOIN tracks         t  ON ii.TrackId = t.TrackId
    JOIN albums         al ON t.AlbumId  = al.AlbumId
    JOIN artists        ar ON al.ArtistId = ar.ArtistId
    GROUP BY ar.ArtistId
),
all_artists AS (
    SELECT a.ArtistId,
           a.Name,
           COALESCE(s.revenue,0) AS revenue
    FROM artists a
    LEFT JOIN artist_sales s ON s.ArtistId = a.ArtistId
),
top_artist AS (          -- highest‑selling (tie → alphabetical)
    SELECT ArtistId
    FROM all_artists
    ORDER BY revenue DESC, Name
    LIMIT 1
),
low_artist AS (          -- lowest‑selling (tie → alphabetical)
    SELECT ArtistId
    FROM all_artists
    ORDER BY revenue ASC, Name
    LIMIT 1
),
customer_artist_spending AS (
    SELECT inv.CustomerId,
           al.ArtistId,
           SUM(ii.UnitPrice * ii.Quantity) AS amount
    FROM invoices       inv
    JOIN invoice_items  ii ON inv.InvoiceId = ii.InvoiceId
    JOIN tracks         t  ON ii.TrackId   = t.TrackId
    JOIN albums         al ON t.AlbumId    = al.AlbumId
    GROUP BY inv.CustomerId, al.ArtistId
),
avg_top AS (
    SELECT AVG(amount) AS avg_val
    FROM customer_artist_spending
    WHERE ArtistId = (SELECT ArtistId FROM top_artist)
),
avg_low AS (
    SELECT AVG(amount) AS avg_val
    FROM customer_artist_spending
    WHERE ArtistId = (SELECT ArtistId FROM low_artist)
)
SELECT ROUND(
         ABS( COALESCE((SELECT avg_val FROM avg_top),0)
            - COALESCE((SELECT avg_val FROM avg_low),0) ), 4
       ) AS difference;