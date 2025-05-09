WITH
-- 1. Artist with the highest overall sales (tie-break on name ASC)
top_artist AS (
    SELECT ar."ArtistId"
    FROM   "artists"        AS ar
    JOIN   "albums"         AS al ON al."ArtistId" = ar."ArtistId"
    JOIN   "tracks"         AS tr ON tr."AlbumId"  = al."AlbumId"
    JOIN   "invoice_items"  AS ii ON ii."TrackId"  = tr."TrackId"
    GROUP  BY ar."ArtistId", ar."Name"
    ORDER  BY SUM(ii."UnitPrice"*ii."Quantity") DESC,
              ar."Name" ASC
    LIMIT  1
),
-- 2. Artist with the lowest overall sales (>0) (tie-break on name ASC)
low_artist AS (
    SELECT ar."ArtistId"
    FROM   "artists"        AS ar
    JOIN   "albums"         AS al ON al."ArtistId" = ar."ArtistId"
    JOIN   "tracks"         AS tr ON tr."AlbumId"  = al."AlbumId"
    JOIN   "invoice_items"  AS ii ON ii."TrackId"  = tr."TrackId"
    GROUP  BY ar."ArtistId", ar."Name"
    HAVING SUM(ii."UnitPrice"*ii."Quantity") > 0
    ORDER  BY SUM(ii."UnitPrice"*ii."Quantity") ASC,
              ar."Name" ASC
    LIMIT  1
),
-- 3. Spending per customer on the top-selling artist
cust_top AS (
    SELECT inv."CustomerId",
           SUM(ii."UnitPrice"*ii."Quantity") AS spend
    FROM   top_artist       AS ta
    JOIN   "albums"         AS al  ON al."ArtistId" = ta."ArtistId"
    JOIN   "tracks"         AS tr  ON tr."AlbumId"  = al."AlbumId"
    JOIN   "invoice_items"  AS ii  ON ii."TrackId"  = tr."TrackId"
    JOIN   "invoices"       AS inv ON inv."InvoiceId" = ii."InvoiceId"
    GROUP  BY inv."CustomerId"
),
-- 4. Spending per customer on the lowest-selling artist
cust_low AS (
    SELECT inv."CustomerId",
           SUM(ii."UnitPrice"*ii."Quantity") AS spend
    FROM   low_artist       AS la
    JOIN   "albums"         AS al  ON al."ArtistId" = la."ArtistId"
    JOIN   "tracks"         AS tr  ON tr."AlbumId"  = al."AlbumId"
    JOIN   "invoice_items"  AS ii  ON ii."TrackId"  = tr."TrackId"
    JOIN   "invoices"       AS inv ON inv."InvoiceId" = ii."InvoiceId"
    GROUP  BY inv."CustomerId"
),
-- 5. Pre-compute the two averages
avgs AS (
    SELECT
        (SELECT AVG(spend) FROM cust_top) AS avg_top,
        (SELECT AVG(spend) FROM cust_low) AS avg_low
)
-- 6. Final result with absolute difference
SELECT
       ROUND(avg_top,4)                                   AS "AvgSpendTopArtist",
       ROUND(avg_low,4)                                   AS "AvgSpendLowArtist",
       ROUND(ABS(avg_top - avg_low),4)                    AS "AbsoluteDifference"
FROM   avgs;