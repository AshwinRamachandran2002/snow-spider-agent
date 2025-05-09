WITH artist_sales AS (
    SELECT 
        ar.ArtistId,
        ar.Name,
        COALESCE(SUM(ii.UnitPrice * ii.Quantity),0) AS revenue
    FROM artists       ar
    LEFT JOIN albums   al ON al.ArtistId = ar.ArtistId
    LEFT JOIN tracks   tr ON tr.AlbumId   = al.AlbumId
    LEFT JOIN invoice_items ii ON ii.TrackId = tr.TrackId
    GROUP BY ar.ArtistId
    HAVING revenue > 0                -- consider only artists that actually sold something
),
max_artist AS (                       -- top‑selling artist (tie → alphabetical)
    SELECT ArtistId, Name, revenue
    FROM   artist_sales
    ORDER  BY revenue DESC, Name ASC
    LIMIT  1
),
min_artist AS (                       -- lowest‑selling artist (tie → alphabetical)
    SELECT ArtistId, Name, revenue
    FROM   artist_sales
    ORDER  BY revenue ASC, Name ASC
    LIMIT  1
),
customer_spending AS (                -- how much every customer spent on each artist
    SELECT 
        inv.CustomerId,
        al.ArtistId,
        SUM(ii.UnitPrice * ii.Quantity) AS spending
    FROM invoice_items ii
    JOIN tracks   tr  ON tr.TrackId  = ii.TrackId
    JOIN albums   al  ON al.AlbumId  = tr.AlbumId
    JOIN invoices inv ON inv.InvoiceId = ii.InvoiceId
    GROUP BY inv.CustomerId, al.ArtistId
),
max_spenders AS (                     -- customers who bought the top artist
    SELECT cs.CustomerId, cs.spending
    FROM   customer_spending cs
    JOIN   max_artist ma ON ma.ArtistId = cs.ArtistId
),
min_spenders AS (                     -- customers who bought the bottom artist
    SELECT cs.CustomerId, cs.spending
    FROM   customer_spending cs
    JOIN   min_artist mi ON mi.ArtistId = cs.ArtistId
),
averages AS (                         -- average spendings per group
    SELECT 
        (SELECT AVG(spending) FROM max_spenders) AS avg_max,
        (SELECT AVG(spending) FROM min_spenders) AS avg_min
)
SELECT 
    ROUND(ABS(avg_max - avg_min), 4) AS difference
FROM averages;