/*--------------------------------------------------------------
STEP-BY-STEP LOGIC
1. artist_sales          : revenue per artist (only artists with >0 revenue)
2. max_artist / min_artist : pick top & bottom revenue artists (alphabetical tie-break)
3. selected_artists      : the two artists of interest
4. customer_artist_spend : what each customer spent on each of those artists
5. artist_avg_spend      : average spend per artist across their buying customers
6. Final SELECT          : absolute difference between the two averages
--------------------------------------------------------------*/
WITH artist_sales AS (
    SELECT
        alb."ArtistId",
        art."Name"                              AS "ArtistName",
        SUM(ii."UnitPrice" * ii."Quantity")     AS "Revenue"
    FROM CHINOOK.CHINOOK.INVOICE_ITEMS  ii
    JOIN CHINOOK.CHINOOK.TRACKS         t   ON t."TrackId"  = ii."TrackId"
    JOIN CHINOOK.CHINOOK.ALBUMS         alb ON alb."AlbumId" = t."AlbumId"
    JOIN CHINOOK.CHINOOK.ARTISTS        art ON art."ArtistId" = alb."ArtistId"
    GROUP BY
        alb."ArtistId",
        art."Name"
    HAVING SUM(ii."UnitPrice" * ii."Quantity") > 0
),
max_artist AS (
    SELECT "ArtistId"
    FROM artist_sales
    ORDER BY "Revenue" DESC NULLS LAST, "ArtistName" ASC
    LIMIT 1
),
min_artist AS (
    SELECT "ArtistId"
    FROM artist_sales
    ORDER BY "Revenue" ASC NULLS LAST, "ArtistName" ASC
    LIMIT 1
),
selected_artists AS (
    SELECT * FROM max_artist
    UNION ALL
    SELECT * FROM min_artist
),
customer_artist_spend AS (
    SELECT
        inv."CustomerId",
        alb."ArtistId",
        SUM(ii."UnitPrice" * ii."Quantity") AS "Spend"
    FROM CHINOOK.CHINOOK.INVOICE_ITEMS ii
    JOIN CHINOOK.CHINOOK.INVOICES      inv ON inv."InvoiceId" = ii."InvoiceId"
    JOIN CHINOOK.CHINOOK.TRACKS        t   ON t."TrackId"    = ii."TrackId"
    JOIN CHINOOK.CHINOOK.ALBUMS        alb ON alb."AlbumId"  = t."AlbumId"
    WHERE alb."ArtistId" IN (SELECT "ArtistId" FROM selected_artists)
    GROUP BY
        inv."CustomerId",
        alb."ArtistId"
),
artist_avg_spend AS (
    SELECT
        "ArtistId",
        AVG("Spend") AS "AvgSpend"
    FROM customer_artist_spend
    GROUP BY "ArtistId"
)
SELECT
    ABS(
        (SELECT "AvgSpend" FROM artist_avg_spend WHERE "ArtistId" = (SELECT "ArtistId" FROM max_artist))
        -
        (SELECT "AvgSpend" FROM artist_avg_spend WHERE "ArtistId" = (SELECT "ArtistId" FROM min_artist))
    ) AS "AbsoluteDifferenceBetweenAverages";