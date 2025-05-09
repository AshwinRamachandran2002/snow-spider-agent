WITH artist_sales AS (
    SELECT ar."ArtistId",
           ar."Name",
           SUM(ii."UnitPrice" * ii."Quantity") AS revenue
    FROM   "artists"        ar
    JOIN   "albums"         al ON al."ArtistId" = ar."ArtistId"
    JOIN   "tracks"         t  ON t."AlbumId"  = al."AlbumId"
    JOIN   "invoice_items"  ii ON ii."TrackId" = t."TrackId"
    GROUP BY ar."ArtistId", ar."Name"
),
top_artist AS (
    SELECT "ArtistId"
    FROM   artist_sales
    ORDER  BY revenue DESC, "Name" ASC
    LIMIT  1
),
bottom_artist AS (
    SELECT "ArtistId"
    FROM   artist_sales
    WHERE  revenue > 0
    ORDER  BY revenue ASC, "Name" ASC
    LIMIT  1
),
cust_top AS (
    SELECT inv."CustomerId",
           SUM(ii."UnitPrice" * ii."Quantity") AS spend
    FROM   top_artist  ta
    JOIN   "albums"    al ON al."ArtistId" = ta."ArtistId"
    JOIN   "tracks"    t  ON t."AlbumId"  = al."AlbumId"
    JOIN   "invoice_items" ii ON ii."TrackId" = t."TrackId"
    JOIN   "invoices"  inv ON inv."InvoiceId" = ii."InvoiceId"
    GROUP BY inv."CustomerId"
),
cust_bottom AS (
    SELECT inv."CustomerId",
           SUM(ii."UnitPrice" * ii."Quantity") AS spend
    FROM   bottom_artist ba
    JOIN   "albums"    al ON al."ArtistId" = ba."ArtistId"
    JOIN   "tracks"    t  ON t."AlbumId"  = al."AlbumId"
    JOIN   "invoice_items" ii ON ii."TrackId" = t."TrackId"
    JOIN   "invoices"  inv ON inv."InvoiceId" = ii."InvoiceId"
    GROUP BY inv."CustomerId"
)
SELECT ROUND(
           ABS( (SELECT AVG(spend) FROM cust_top)
              - (SELECT AVG(spend) FROM cust_bottom) ),
       4) AS average_spend_difference;