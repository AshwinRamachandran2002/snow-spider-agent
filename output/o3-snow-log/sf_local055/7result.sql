WITH artist_sales AS (   -- total revenue per artist
    SELECT 
        ar."ArtistId",
        ar."Name"        AS "ArtistName",
        SUM(ii."UnitPrice" * ii."Quantity") AS "TotalSales"
    FROM CHINOOK.CHINOOK.ARTISTS        ar
    JOIN CHINOOK.CHINOOK.ALBUMS         al ON al."ArtistId" = ar."ArtistId"
    JOIN CHINOOK.CHINOOK.TRACKS         tr ON tr."AlbumId"  = al."AlbumId"
    JOIN CHINOOK.CHINOOK.INVOICE_ITEMS  ii ON ii."TrackId"  = tr."TrackId"
    GROUP BY ar."ArtistId", ar."Name"
),

/* pick highest-selling and lowest-selling artist (ties → alphabetic) */
selected_artists AS (
    SELECT "ArtistId", "ArtistName", 'TOP' AS "ArtistLevel"
    FROM artist_sales
    QUALIFY ROW_NUMBER() OVER (ORDER BY "TotalSales" DESC, "ArtistName" ASC) = 1
    
    UNION ALL
    
    SELECT "ArtistId", "ArtistName", 'BOTTOM' AS "ArtistLevel"
    FROM artist_sales
    QUALIFY ROW_NUMBER() OVER (ORDER BY "TotalSales" ASC,  "ArtistName" ASC) = 1
),

/* what each customer spent on those two artists */
customer_spending AS (
    SELECT
        inv."CustomerId",
        sa."ArtistLevel",
        SUM(ii."UnitPrice" * ii."Quantity") AS "CustomerSpend"
    FROM CHINOOK.CHINOOK.INVOICES        inv
    JOIN CHINOOK.CHINOOK.INVOICE_ITEMS   ii ON ii."InvoiceId" = inv."InvoiceId"
    JOIN CHINOOK.CHINOOK.TRACKS          tr ON tr."TrackId"   = ii."TrackId"
    JOIN CHINOOK.CHINOOK.ALBUMS          al ON al."AlbumId"   = tr."AlbumId"
    JOIN selected_artists                sa ON sa."ArtistId"  = al."ArtistId"
    GROUP BY inv."CustomerId", sa."ArtistLevel"
),

/* average spend per artist level (only customers who bought that artist) */
avg_spending AS (
    SELECT
        "ArtistLevel",
        AVG("CustomerSpend") AS "AvgSpend"
    FROM customer_spending
    GROUP BY "ArtistLevel"
)

/* absolute difference between the two averages */
SELECT ABS(
         COALESCE(MAX(CASE WHEN "ArtistLevel" = 'TOP'    THEN "AvgSpend" END), 0)
         -
         COALESCE(MAX(CASE WHEN "ArtistLevel" = 'BOTTOM' THEN "AvgSpend" END), 0)
       ) AS "ABS_DIFF_BETWEEN_AVERAGES"
FROM avg_spending;