WITH best_selling_artist AS (
    /* 1️⃣ Identify the artist with the greatest overall revenue */
    SELECT ar."ArtistId"
    FROM   "invoice_items" AS ii
    JOIN   "tracks"        AS tr ON ii."TrackId" = tr."TrackId"
    JOIN   "albums"        AS al ON tr."AlbumId" = al."AlbumId"
    JOIN   "artists"       AS ar ON al."ArtistId" = ar."ArtistId"
    GROUP  BY ar."ArtistId"
    ORDER  BY SUM(ii."UnitPrice" * ii."Quantity") DESC
    LIMIT 1
),
customer_totals AS (
    /* 2️⃣ Compute each customer's spend on that best-selling artist */
    SELECT cu."FirstName",
           SUM(ii."UnitPrice" * ii."Quantity") AS AmountSpent
    FROM   "customers"     AS cu
    JOIN   "invoices"      AS inv ON cu."CustomerId" = inv."CustomerId"
    JOIN   "invoice_items" AS ii  ON inv."InvoiceId" = ii."InvoiceId"
    JOIN   "tracks"        AS tr  ON ii."TrackId" = tr."TrackId"
    JOIN   "albums"        AS al  ON tr."AlbumId" = al."AlbumId"
    WHERE  al."ArtistId" = (SELECT "ArtistId" FROM best_selling_artist)
    GROUP  BY cu."FirstName"
)
SELECT "FirstName",
       ROUND(AmountSpent, 2) AS AmountSpent
FROM   customer_totals
WHERE  AmountSpent < 1
ORDER  BY AmountSpent, "FirstName";