WITH artist_sales AS (
    SELECT
        ar.ArtistId,
        ar.Name,
        COALESCE(SUM(ii.UnitPrice * ii.Quantity),0.0) AS sales
    FROM artists ar
    LEFT JOIN albums       al ON al.ArtistId = ar.ArtistId
    LEFT JOIN tracks        t ON t.AlbumId   = al.AlbumId
    LEFT JOIN invoice_items ii ON ii.TrackId = t.TrackId
    GROUP BY ar.ArtistId
),
ranked AS (
    SELECT
        ArtistId,
        Name,
        sales,
        RANK() OVER (ORDER BY sales DESC, Name ASC) AS rnk_high,
        RANK() OVER (ORDER BY sales ASC , Name ASC) AS rnk_low
    FROM artist_sales
),
targets AS (                 -- top‑selling and lowest‑selling artists
    SELECT *
    FROM ranked
    WHERE rnk_high = 1 OR rnk_low = 1
),
customer_spending AS (       -- what each customer spent on those artists
    SELECT
        inv.CustomerId,
        ar.ArtistId,
        SUM(ii.UnitPrice * ii.Quantity) AS amount
    FROM invoice_items ii
    JOIN tracks   t   ON t.TrackId  = ii.TrackId
    JOIN albums   al  ON al.AlbumId = t.AlbumId
    JOIN artists  ar  ON ar.ArtistId= al.ArtistId
    JOIN invoices inv ON inv.InvoiceId = ii.InvoiceId
    WHERE ar.ArtistId IN (SELECT ArtistId FROM targets)
    GROUP BY inv.CustomerId, ar.ArtistId
),
avg_spending AS (            -- average spending per artist (only customers who bought)
    SELECT
        t.ArtistId,
        CASE WHEN t.rnk_high = 1 THEN 'top' ELSE 'bottom' END AS category,
        AVG(cs.amount) AS avg_amount
    FROM targets t
    LEFT JOIN customer_spending cs ON cs.ArtistId = t.ArtistId
    GROUP BY t.ArtistId, category
),
diff AS (                     -- absolute difference between the two averages
    SELECT ABS(
        COALESCE(MAX(CASE WHEN category = 'top'    THEN avg_amount END),0.0) -
        COALESCE(MAX(CASE WHEN category = 'bottom' THEN avg_amount END),0.0)
    ) AS avg_difference
    FROM avg_spending
)
SELECT avg_difference
FROM diff;