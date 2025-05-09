WITH best_selling_artist AS (
    SELECT ar.ArtistId
    FROM artists ar
    JOIN albums  al ON al.ArtistId = ar.ArtistId
    JOIN tracks  t  ON t.AlbumId   = al.AlbumId
    JOIN invoice_items ii ON ii.TrackId = t.TrackId
    GROUP BY ar.ArtistId
    ORDER BY SUM(ii.UnitPrice * ii.Quantity) DESC, ar.ArtistId
    LIMIT 1
),
customer_spending AS (
    SELECT c.CustomerId,
           c.FirstName AS first_name,
           SUM(ii.UnitPrice * ii.Quantity) AS amount_spent
    FROM best_selling_artist bsa
    JOIN albums  al ON al.ArtistId = bsa.ArtistId
    JOIN tracks  t  ON t.AlbumId   = al.AlbumId
    JOIN invoice_items ii ON ii.TrackId = t.TrackId
    JOIN invoices i ON i.InvoiceId = ii.InvoiceId
    JOIN customers c ON c.CustomerId = i.CustomerId
    GROUP BY c.CustomerId
)
SELECT first_name,
       printf('%.4f', amount_spent) AS amount_spent
FROM customer_spending
WHERE amount_spent < 1
ORDER BY amount_spent, first_name;