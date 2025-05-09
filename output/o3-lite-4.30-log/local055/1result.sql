WITH artist_sales AS (
    SELECT
        ar.ArtistId,
        ar.Name,
        COALESCE(SUM(ii.UnitPrice * ii.Quantity),0) AS total_sales
    FROM artists ar
    LEFT JOIN albums        al ON al.ArtistId = ar.ArtistId
    LEFT JOIN tracks        t  ON t.AlbumId   = al.AlbumId
    LEFT JOIN invoice_items ii ON ii.TrackId  = t.TrackId
    GROUP BY ar.ArtistId, ar.Name
),
top_artist AS (          -- highest sales (tie‑break alphabetical)
    SELECT ArtistId
    FROM artist_sales
    ORDER BY total_sales DESC, Name ASC
    LIMIT 1
),
bottom_artist AS (       -- lowest sales > 0 (tie‑break alphabetical)
    SELECT ArtistId
    FROM artist_sales
    WHERE total_sales > 0
    ORDER BY total_sales ASC, Name ASC
    LIMIT 1
),
top_customer_spend AS (
    SELECT inv.CustomerId,
           SUM(ii.UnitPrice * ii.Quantity) AS spend
    FROM invoice_items ii
    JOIN tracks   t   ON t.TrackId  = ii.TrackId
    JOIN albums   al  ON al.AlbumId = t.AlbumId
    JOIN invoices inv ON inv.InvoiceId = ii.InvoiceId
    WHERE al.ArtistId = (SELECT ArtistId FROM top_artist)
    GROUP BY inv.CustomerId
),
bottom_customer_spend AS (
    SELECT inv.CustomerId,
           SUM(ii.UnitPrice * ii.Quantity) AS spend
    FROM invoice_items ii
    JOIN tracks   t   ON t.TrackId  = ii.TrackId
    JOIN albums   al  ON al.AlbumId = t.AlbumId
    JOIN invoices inv ON inv.InvoiceId = ii.InvoiceId
    WHERE al.ArtistId = (SELECT ArtistId FROM bottom_artist)
    GROUP BY inv.CustomerId
),
averages AS (
    SELECT
        (SELECT AVG(spend) FROM top_customer_spend)    AS avg_top,
        (SELECT AVG(spend) FROM bottom_customer_spend) AS avg_bottom
)
SELECT
    ROUND(ABS(avg_top - avg_bottom),4) AS average_spend_difference
FROM averages;