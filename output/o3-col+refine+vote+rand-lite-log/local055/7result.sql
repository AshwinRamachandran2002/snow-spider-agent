WITH artist_revenue AS (
    SELECT  a."ArtistId",
            a."Name",
            SUM(ii."UnitPrice" * ii."Quantity") AS Revenue
    FROM    "artists" a
    JOIN    "albums"  al ON al."ArtistId" = a."ArtistId"
    JOIN    "tracks"  t  ON t."AlbumId"  = al."AlbumId"
    JOIN    "invoice_items" ii ON ii."TrackId" = t."TrackId"
    GROUP BY a."ArtistId"
),
top_artist AS (
    SELECT "ArtistId"
    FROM   artist_revenue
    ORDER  BY Revenue DESC, "Name" ASC
    LIMIT  1
),
bottom_artist AS (
    SELECT "ArtistId"
    FROM   artist_revenue
    WHERE  Revenue > 0                    -- ignore artists with no sales
    ORDER  BY Revenue ASC, "Name" ASC
    LIMIT  1
),
customer_top_spend AS (
    SELECT  c."CustomerId",
            SUM(ii."UnitPrice" * ii."Quantity") AS Spend
    FROM    top_artist ta
    JOIN    "albums"  al ON al."ArtistId" = ta."ArtistId"
    JOIN    "tracks"  t  ON t."AlbumId"  = al."AlbumId"
    JOIN    "invoice_items" ii ON ii."TrackId" = t."TrackId"
    JOIN    "invoices" i  ON i."InvoiceId" = ii."InvoiceId"
    JOIN    "customers" c ON c."CustomerId" = i."CustomerId"
    GROUP BY c."CustomerId"
),
customer_bottom_spend AS (
    SELECT  c."CustomerId",
            SUM(ii."UnitPrice" * ii."Quantity") AS Spend
    FROM    bottom_artist ba
    JOIN    "albums"  al ON al."ArtistId" = ba."ArtistId"
    JOIN    "tracks"  t  ON t."AlbumId"  = al."AlbumId"
    JOIN    "invoice_items" ii ON ii."TrackId" = t."TrackId"
    JOIN    "invoices" i  ON i."InvoiceId" = ii."InvoiceId"
    JOIN    "customers" c ON c."CustomerId" = i."CustomerId"
    GROUP BY c."CustomerId"
)
SELECT ROUND(
         ABS(
           (SELECT AVG(Spend) FROM customer_top_spend) -
           (SELECT AVG(Spend) FROM customer_bottom_spend)
         )
       , 4) AS AbsoluteAverageDifference;