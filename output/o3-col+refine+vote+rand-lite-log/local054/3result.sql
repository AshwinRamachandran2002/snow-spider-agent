-- First-name and spending (< $1) on albums by the best-selling artist
WITH BestSellingArtist AS (
    SELECT ar."ArtistId"
    FROM   "invoice_items" AS ii
    JOIN   "tracks"        AS t  ON ii."TrackId" = t."TrackId"
    JOIN   "albums"        AS al ON t."AlbumId"  = al."AlbumId"
    JOIN   "artists"       AS ar ON al."ArtistId"= ar."ArtistId"
    GROUP  BY ar."ArtistId"
    ORDER  BY SUM(ii."UnitPrice" * ii."Quantity") DESC
    LIMIT  1
)
SELECT  c."FirstName",
        ROUND(SUM(ii."UnitPrice" * ii."Quantity"), 4) AS "AmountSpent"
FROM        "customers"     AS c
JOIN        "invoices"      AS i  ON c."CustomerId" = i."CustomerId"
JOIN        "invoice_items" AS ii ON i."InvoiceId"   = ii."InvoiceId"
JOIN        "tracks"        AS t  ON ii."TrackId"    = t."TrackId"
JOIN        "albums"        AS al ON t."AlbumId"     = al."AlbumId"
WHERE       al."ArtistId" = (SELECT "ArtistId" FROM BestSellingArtist)
GROUP BY    c."FirstName"
HAVING      SUM(ii."UnitPrice" * ii."Quantity") < 1;