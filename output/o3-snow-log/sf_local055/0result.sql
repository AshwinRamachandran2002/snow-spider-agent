WITH artist_sales AS (   -- total revenue per artist
    SELECT
        AR."ArtistId",
        AR."Name"      AS "ArtistName",
        SUM(II."UnitPrice" * II."Quantity") AS "TotalSales"
    FROM CHINOOK.CHINOOK.INVOICE_ITEMS  II
    JOIN CHINOOK.CHINOOK.TRACKS          T   ON II."TrackId"  = T."TrackId"
    JOIN CHINOOK.CHINOOK.ALBUMS          AL  ON T."AlbumId"   = AL."AlbumId"
    JOIN CHINOOK.CHINOOK.ARTISTS         AR  ON AL."ArtistId" = AR."ArtistId"
    GROUP BY AR."ArtistId", AR."Name"
    HAVING SUM(II."UnitPrice" * II."Quantity") > 0          -- keep artists with sales
),
top_artist AS (          -- highest-selling artist (tie → alphabetical)
    SELECT "ArtistId"
    FROM artist_sales
    QUALIFY ROW_NUMBER() OVER (ORDER BY "TotalSales" DESC, "ArtistName" ASC) = 1
),
bottom_artist AS (       -- lowest-selling artist (tie → alphabetical)
    SELECT "ArtistId"
    FROM artist_sales
    QUALIFY ROW_NUMBER() OVER (ORDER BY "TotalSales" ASC,  "ArtistName" ASC) = 1
),
customer_artist_spend AS (  -- spend per customer per artist
    SELECT
        I."CustomerId",
        AR."ArtistId",
        SUM(II."UnitPrice" * II."Quantity") AS "Spend"
    FROM CHINOOK.CHINOOK.INVOICE_ITEMS  II
    JOIN CHINOOK.CHINOOK.INVOICES       I   ON II."InvoiceId" = I."InvoiceId"
    JOIN CHINOOK.CHINOOK.TRACKS         T   ON II."TrackId"   = T."TrackId"
    JOIN CHINOOK.CHINOOK.ALBUMS         AL  ON T."AlbumId"    = AL."AlbumId"
    JOIN CHINOOK.CHINOOK.ARTISTS        AR  ON AL."ArtistId"  = AR."ArtistId"
    GROUP BY I."CustomerId", AR."ArtistId"
),
top_customer_spend AS (     -- spend per customer on the top artist
    SELECT "CustomerId", "Spend"
    FROM customer_artist_spend
    WHERE "ArtistId" IN (SELECT "ArtistId" FROM top_artist)
),
bottom_customer_spend AS (  -- spend per customer on the bottom artist
    SELECT "CustomerId", "Spend"
    FROM customer_artist_spend
    WHERE "ArtistId" IN (SELECT "ArtistId" FROM bottom_artist)
),
top_avg AS (                -- average spend among customers who bought top artist
    SELECT AVG("Spend") AS avg_top
    FROM   top_customer_spend
),
bottom_avg AS (             -- average spend among customers who bought bottom artist
    SELECT AVG("Spend") AS avg_bottom
    FROM   bottom_customer_spend
)
SELECT
    ABS(t.avg_top - b.avg_bottom) AS "AverageSpendDifference"
FROM top_avg t
CROSS JOIN bottom_avg b;