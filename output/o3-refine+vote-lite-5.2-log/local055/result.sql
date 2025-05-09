WITH artist_sales AS (
    /* 1.  Total sales by artist */
    SELECT  ar."ArtistId",
            ar."Name",
            SUM(ii."UnitPrice" * ii."Quantity")             AS total_sales
    FROM        "invoice_items"  AS ii
    JOIN        "tracks"         AS t   ON t."TrackId"  = ii."TrackId"
    JOIN        "albums"         AS al  ON al."AlbumId" = t."AlbumId"
    JOIN        "artists"        AS ar  ON ar."ArtistId"= al."ArtistId"
    GROUP BY    ar."ArtistId", ar."Name"
),
ranked AS (
    /* 2.  Rank artists for top and bottom sellers
           – alphabetically break ties                                    */
    SELECT  *,
            RANK() OVER (ORDER BY total_sales DESC, "Name" ASC) AS rnk_top,
            RANK() OVER (ORDER BY total_sales ASC,  "Name" ASC) AS rnk_bottom
    FROM    artist_sales
),
chosen_artists AS (
    /* 3.  Keep just the best and worst selling artists */
    SELECT  "ArtistId",
            "Name",
            CASE WHEN rnk_top    = 1 THEN 'top'
                 ELSE                  'bottom' END           AS position
    FROM    ranked
    WHERE   rnk_top = 1 OR rnk_bottom = 1
),
customer_spending AS (
    /* 4.  How much each customer spent on each of those artists */
    SELECT  inv."CustomerId",
            ca."ArtistId",
            SUM(ii."UnitPrice" * ii."Quantity")               AS amount
    FROM        "invoice_items"  AS ii
    JOIN        "invoices"       AS inv ON inv."InvoiceId" = ii."InvoiceId"
    JOIN        "tracks"         AS t   ON t."TrackId"     = ii."TrackId"
    JOIN        "albums"         AS al  ON al."AlbumId"    = t."AlbumId"
    JOIN        chosen_artists   AS ca  ON ca."ArtistId"   = al."ArtistId"
    GROUP BY    inv."CustomerId", ca."ArtistId"
),
avg_spending AS (
    /* 5.  Average spend per artist (only customers who bought that artist) */
    SELECT  ca.position,
            AVG(cs.amount)                               AS avg_amount
    FROM        chosen_artists   AS ca
    JOIN        customer_spending AS cs ON cs."ArtistId" = ca."ArtistId"
    GROUP BY    ca.position
)
/* 6.  Absolute difference between the two averages */
SELECT  ABS( (SELECT avg_amount FROM avg_spending WHERE position = 'top')
           - (SELECT avg_amount FROM avg_spending WHERE position = 'bottom')
         )        AS avg_spending_difference;