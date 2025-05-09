WITH artist_sales AS (
    /* 1.  Total sales for every artist                                */
    SELECT  ar."ArtistId",
            ar."Name",
            SUM(ii."UnitPrice" * ii."Quantity") AS "TotalSales"
    FROM   "invoice_items"  AS ii
    JOIN   "tracks"         AS tr  ON tr."TrackId"  = ii."TrackId"
    JOIN   "albums"         AS al  ON al."AlbumId"  = tr."AlbumId"
    JOIN   "artists"        AS ar  ON ar."ArtistId" = al."ArtistId"
    GROUP  BY ar."ArtistId", ar."Name"
),
/* 2.  Highest- and lowest-selling artists (alphabetical tie-break)   */
top_artist AS (
    SELECT "ArtistId", "Name"
    FROM   artist_sales
    ORDER  BY "TotalSales" DESC, "Name"
    LIMIT  1
),
low_artist AS (
    SELECT "ArtistId", "Name"
    FROM   artist_sales
    ORDER  BY "TotalSales" ASC,  "Name"
    LIMIT  1
),
/* 3.  What each customer spent on the top-selling artist             */
customer_top_spend AS (
    SELECT  c."CustomerId",
            SUM(ii."UnitPrice" * ii."Quantity") AS "Spent"
    FROM    "customers"      AS c
    JOIN    "invoices"       AS inv ON inv."CustomerId" = c."CustomerId"
    JOIN    "invoice_items"  AS ii  ON ii."InvoiceId"   = inv."InvoiceId"
    JOIN    "tracks"         AS tr  ON tr."TrackId"     = ii."TrackId"
    JOIN    "albums"         AS al  ON al."AlbumId"     = tr."AlbumId"
    JOIN    top_artist       AS ta  ON ta."ArtistId"    = al."ArtistId"
    GROUP   BY c."CustomerId"
),
/* 4.  What each customer spent on the lowest-selling artist          */
customer_low_spend AS (
    SELECT  c."CustomerId",
            SUM(ii."UnitPrice" * ii."Quantity") AS "Spent"
    FROM    "customers"      AS c
    JOIN    "invoices"       AS inv ON inv."CustomerId" = c."CustomerId"
    JOIN    "invoice_items"  AS ii  ON ii."InvoiceId"   = inv."InvoiceId"
    JOIN    "tracks"         AS tr  ON tr."TrackId"     = ii."TrackId"
    JOIN    "albums"         AS al  ON al."AlbumId"     = tr."AlbumId"
    JOIN    low_artist       AS la  ON la."ArtistId"    = al."ArtistId"
    GROUP   BY c."CustomerId"
),
/* 5.  Average spend for both groups                                  */
avg_spends AS (
    SELECT  (SELECT AVG("Spent") FROM customer_top_spend) AS "AvgTop",
            (SELECT AVG("Spent") FROM customer_low_spend) AS "AvgLow"
)
/* 6.  Absolute difference between the two averages                   */
SELECT  ABS("AvgTop" - "AvgLow") AS "AverageSpendDifference"
FROM    avg_spends;