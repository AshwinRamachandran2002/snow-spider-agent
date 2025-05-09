WITH best_selling_artist AS (
    /* Identify the single best-selling artist */
    SELECT a."ArtistId"
    FROM   "invoice_items" AS ii
    JOIN   "tracks"        AS t  ON ii."TrackId" = t."TrackId"
    JOIN   "albums"        AS a  ON t."AlbumId"  = a."AlbumId"
    GROUP  BY a."ArtistId"
    ORDER  BY SUM(ii."UnitPrice" * ii."Quantity") DESC
    LIMIT 1
)
SELECT  c."FirstName",
        SUM(ii."UnitPrice" * ii."Quantity") AS "Amount_Spent"
FROM    "customers"     AS c
JOIN    "invoices"      AS inv ON c."CustomerId" = inv."CustomerId"
JOIN    "invoice_items" AS ii  ON inv."InvoiceId" = ii."InvoiceId"
JOIN    "tracks"        AS t   ON ii."TrackId"    = t."TrackId"
JOIN    "albums"        AS al  ON t."AlbumId"     = al."AlbumId"
JOIN    best_selling_artist b  ON al."ArtistId"   = b."ArtistId"   -- restrict to best-seller
GROUP   BY c."CustomerId"
HAVING  SUM(ii."UnitPrice" * ii."Quantity") < 1;