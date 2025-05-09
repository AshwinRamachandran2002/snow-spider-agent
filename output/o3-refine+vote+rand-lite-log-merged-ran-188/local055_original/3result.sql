WITH artist_sales AS (
    SELECT 
        ar.ArtistId,
        ar.Name,
        SUM(ii.UnitPrice * ii.Quantity) AS total_sales
    FROM artists          ar
    JOIN albums           al ON al.ArtistId = ar.ArtistId
    JOIN tracks           t  ON t.AlbumId   = al.AlbumId
    JOIN invoice_items    ii ON ii.TrackId  = t.TrackId
    GROUP BY ar.ArtistId, ar.Name
), 
top_artist AS (
    SELECT ArtistId, Name 
    FROM artist_sales 
    ORDER BY total_sales DESC, Name ASC 
    LIMIT 1
), 
bottom_artist AS (
    SELECT ArtistId, Name 
    FROM artist_sales 
    ORDER BY total_sales ASC, Name ASC 
    LIMIT 1
), 
customer_spending AS (
    SELECT 
        inv.CustomerId,
        ar.ArtistId,
        SUM(ii.UnitPrice * ii.Quantity) AS amount
    FROM invoices       inv
    JOIN invoice_items  ii ON ii.InvoiceId = inv.InvoiceId
    JOIN tracks         t  ON t.TrackId    = ii.TrackId
    JOIN albums         al ON al.AlbumId   = t.AlbumId
    JOIN artists        ar ON ar.ArtistId  = al.ArtistId
    WHERE ar.ArtistId IN (
          SELECT ArtistId FROM top_artist
          UNION
          SELECT ArtistId FROM bottom_artist)
    GROUP BY inv.CustomerId, ar.ArtistId
), 
top_avg AS (
    SELECT AVG(amount) AS avg_top
    FROM customer_spending
    WHERE ArtistId = (SELECT ArtistId FROM top_artist)
), 
bottom_avg AS (
    SELECT AVG(amount) AS avg_bottom
    FROM customer_spending
    WHERE ArtistId = (SELECT ArtistId FROM bottom_artist)
)
SELECT 
    ABS( (SELECT avg_top    FROM top_avg) 
        - (SELECT avg_bottom FROM bottom_avg) ) 
    AS avg_difference;