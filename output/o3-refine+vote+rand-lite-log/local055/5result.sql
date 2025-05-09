WITH artist_sales AS (
    SELECT  ar.ArtistId,
            ar.Name,
            COALESCE(SUM(ii.UnitPrice * ii.Quantity),0)       AS total_sales
    FROM        artists        ar
    LEFT JOIN   albums         al  ON al.ArtistId = ar.ArtistId
    LEFT JOIN   tracks         t   ON t.AlbumId   = al.AlbumId
    LEFT JOIN   invoice_items  ii  ON ii.TrackId  = t.TrackId
    GROUP BY    ar.ArtistId,
                ar.Name
),
top_artist AS (
    SELECT ArtistId, Name
    FROM   artist_sales
    ORDER  BY total_sales DESC, Name ASC
    LIMIT  1
),
bottom_artist AS (
    SELECT ArtistId, Name
    FROM   artist_sales
    ORDER  BY total_sales ASC, Name ASC
    LIMIT  1
),
customer_spending AS (
    SELECT  c.CustomerId,
            COALESCE(SUM(CASE WHEN a.ArtistId = ta.ArtistId 
                              THEN ii.UnitPrice * ii.Quantity END),0) AS top_spent,
            COALESCE(SUM(CASE WHEN a.ArtistId = ba.ArtistId 
                              THEN ii.UnitPrice * ii.Quantity END),0) AS bottom_spent
    FROM        customers      c
    CROSS JOIN  top_artist     ta
    CROSS JOIN  bottom_artist  ba
    LEFT JOIN   invoices       i   ON i.CustomerId = c.CustomerId
    LEFT JOIN   invoice_items  ii  ON ii.InvoiceId = i.InvoiceId
    LEFT JOIN   tracks         t   ON t.TrackId    = ii.TrackId
    LEFT JOIN   albums         al  ON al.AlbumId   = t.AlbumId
    LEFT JOIN   artists        a   ON a.ArtistId   = al.ArtistId
    GROUP BY    c.CustomerId
),
average_values AS (
    SELECT  (SELECT AVG(top_spent) 
             FROM   customer_spending 
             WHERE  top_spent  > 0)                  AS avg_top,
            (SELECT AVG(bottom_spent) 
             FROM   customer_spending 
             WHERE  bottom_spent > 0)                AS avg_bottom
)
SELECT ABS(avg_top - avg_bottom) AS difference
FROM   average_values;