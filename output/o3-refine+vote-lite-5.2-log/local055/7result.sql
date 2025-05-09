WITH sales_per_artist AS (
    SELECT ar."ArtistId",
           ar."Name",
           SUM(ii."UnitPrice" * ii."Quantity") AS TotalSales
    FROM artists ar
    JOIN albums  al ON al."ArtistId" = ar."ArtistId"
    JOIN tracks  tr ON tr."AlbumId"  = al."AlbumId"
    JOIN invoice_items ii ON ii."TrackId" = tr."TrackId"
    GROUP BY ar."ArtistId", ar."Name"
),
top_artist AS (          -- artist with the highest overall sales (tie ⇒ alphabetical)
    SELECT "ArtistId", "Name"
    FROM   sales_per_artist
    ORDER  BY TotalSales DESC, "Name"
    LIMIT  1
),
bottom_artist AS (       -- artist with the lowest overall sales (tie ⇒ alphabetical)
    SELECT "ArtistId", "Name"
    FROM   sales_per_artist
    ORDER  BY TotalSales ASC, "Name"
    LIMIT  1
),
top_spending AS (        -- what each customer spent on the top‑selling artist
    SELECT inv."CustomerId",
           SUM(ii."UnitPrice" * ii."Quantity") AS Spend
    FROM   invoices       inv
    JOIN   invoice_items  ii ON ii."InvoiceId" = inv."InvoiceId"
    JOIN   tracks         tr ON tr."TrackId"   = ii."TrackId"
    JOIN   albums         al ON al."AlbumId"   = tr."AlbumId"
    JOIN   top_artist     ta ON ta."ArtistId"  = al."ArtistId"
    GROUP  BY inv."CustomerId"
),
bottom_spending AS (     -- what each customer spent on the lowest‑selling artist
    SELECT inv."CustomerId",
           SUM(ii."UnitPrice" * ii."Quantity") AS Spend
    FROM   invoices        inv
    JOIN   invoice_items   ii ON ii."InvoiceId" = inv."InvoiceId"
    JOIN   tracks          tr ON tr."TrackId"   = ii."TrackId"
    JOIN   albums          al ON al."AlbumId"   = tr."AlbumId"
    JOIN   bottom_artist   ba ON ba."ArtistId"  = al."ArtistId"
    GROUP  BY inv."CustomerId"
),
avg_values AS (          -- average spend among customers who bought from each artist
    SELECT (SELECT AVG(Spend) FROM top_spending)    AS avg_top,
           (SELECT AVG(Spend) FROM bottom_spending) AS avg_bottom
)
SELECT ABS(avg_top - avg_bottom) AS Difference
FROM   avg_values;