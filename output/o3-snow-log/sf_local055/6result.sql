WITH
/* 1.  Sales generated per (artist, customer) */
"CUST_ARTIST_SALES" AS (
    SELECT
        ar."ArtistId",
        ar."Name"                 AS "ARTIST_NAME",
        inv."CustomerId",
        SUM(ii."UnitPrice" * ii."Quantity") AS "SALES"
    FROM CHINOOK.CHINOOK."INVOICE_ITEMS"  ii
    JOIN CHINOOK.CHINOOK."INVOICES"       inv ON inv."InvoiceId" = ii."InvoiceId"
    JOIN CHINOOK.CHINOOK."TRACKS"         t   ON t."TrackId"     = ii."TrackId"
    JOIN CHINOOK.CHINOOK."ALBUMS"         al  ON al."AlbumId"    = t."AlbumId"
    JOIN CHINOOK.CHINOOK."ARTISTS"        ar  ON ar."ArtistId"   = al."ArtistId"
    GROUP BY ar."ArtistId", ar."Name", inv."CustomerId"
),

/* 2.  Total sales per artist */
"ARTIST_SALES" AS (
    SELECT
        "ArtistId",
        "ARTIST_NAME",
        SUM("SALES") AS "TOTAL_SALES"
    FROM "CUST_ARTIST_SALES"
    GROUP BY "ArtistId", "ARTIST_NAME"
),

/* 3.  Rank artists to get highest & lowest sellers (alphabetical tiebreak) */
"RANKED_ARTISTS" AS (
    SELECT
        *,
        RANK() OVER (ORDER BY "TOTAL_SALES" DESC, "ARTIST_NAME" ASC) AS "R_DESC",
        RANK() OVER (ORDER BY "TOTAL_SALES" ASC,  "ARTIST_NAME" ASC) AS "R_ASC"
    FROM "ARTIST_SALES"
),

/* 4.  Keep only top-selling and bottom-selling artists */
"TARGET_ARTISTS" AS (
    SELECT
        "ArtistId",
        "ARTIST_NAME",
        CASE
            WHEN "R_DESC" = 1 THEN 'TOP'
            ELSE 'BOTTOM'
        END AS "ARTIST_RANK"
    FROM "RANKED_ARTISTS"
    WHERE "R_DESC" = 1
       OR "R_ASC"  = 1
),

/* 5.  Amount each customer spent on those target artists */
"CUSTOMER_SPENDING" AS (
    SELECT
        cas."CustomerId",
        ta."ARTIST_RANK",
        SUM(cas."SALES") AS "AMOUNT_SPENT"
    FROM "CUST_ARTIST_SALES" cas
    JOIN "TARGET_ARTISTS"    ta
      ON ta."ArtistId" = cas."ArtistId"
    GROUP BY cas."CustomerId", ta."ARTIST_RANK"
),

/* 6.  Average spending per artist rank (top vs bottom) */
"AVERAGE_SPENDING" AS (
    SELECT
        "ARTIST_RANK",
        AVG("AMOUNT_SPENT") AS "AVG_SPENT"
    FROM "CUSTOMER_SPENDING"
    GROUP BY "ARTIST_RANK"
)

/* 7.  Absolute difference between the two averages */
SELECT ABS(
           MAX(CASE WHEN "ARTIST_RANK" = 'TOP'    THEN "AVG_SPENT" END) -
           MAX(CASE WHEN "ARTIST_RANK" = 'BOTTOM' THEN "AVG_SPENT" END)
       ) AS "ABS_AVG_SPENDING_DIFF"
FROM "AVERAGE_SPENDING";