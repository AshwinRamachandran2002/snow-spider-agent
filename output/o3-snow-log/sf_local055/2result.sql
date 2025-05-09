WITH artist_sales AS (            -- total sales value per artist
    SELECT 
        ar."ArtistId",
        ar."Name"                                            AS artist_name,
        SUM(ii."UnitPrice" * ii."Quantity")                 AS total_sales
    FROM CHINOOK.CHINOOK.INVOICE_ITEMS  ii
    JOIN CHINOOK.CHINOOK.TRACKS         t  ON t."TrackId"  = ii."TrackId"
    JOIN CHINOOK.CHINOOK.ALBUMS         al ON al."AlbumId" = t."AlbumId"
    JOIN CHINOOK.CHINOOK.ARTISTS        ar ON ar."ArtistId"= al."ArtistId"
    GROUP BY ar."ArtistId", ar."Name"
),

ranked AS (                   -- rank artists for highest and lowest sales (alpha tie-break)
    SELECT
        artist_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC, artist_name ASC) AS rnk_desc,
        RANK() OVER (ORDER BY total_sales ASC , artist_name ASC) AS rnk_asc
    FROM artist_sales
),

chosen AS (                   -- keep only the top-selling and the lowest-selling artist
    SELECT 
        artist_name,
        total_sales,
        CASE 
            WHEN rnk_desc = 1 THEN 'TOP'
            WHEN rnk_asc  = 1 THEN 'LOW'
        END                                                     AS category
    FROM ranked
    WHERE rnk_desc = 1 OR rnk_asc = 1
),

spending AS (                 -- how much each customer spent on those artists
    SELECT
        inv."CustomerId",
        ch.artist_name,
        SUM(ii."UnitPrice" * ii."Quantity")                     AS customer_spend
    FROM CHINOOK.CHINOOK.INVOICE_ITEMS  ii
    JOIN CHINOOK.CHINOOK.TRACKS         t  ON t."TrackId"  = ii."TrackId"
    JOIN CHINOOK.CHINOOK.ALBUMS         al ON al."AlbumId" = t."AlbumId"
    JOIN CHINOOK.CHINOOK.ARTISTS        ar ON ar."ArtistId"= al."ArtistId"
    JOIN CHINOOK.CHINOOK.INVOICES       inv ON inv."InvoiceId" = ii."InvoiceId"
    JOIN chosen                         ch  ON ch.artist_name  = ar."Name"
    GROUP BY inv."CustomerId", ch.artist_name
),

avg_spending AS (             -- average per-customer spending for each of the two artists
    SELECT
        ch.category,
        AVG(sp.customer_spend)                                  AS avg_spend
    FROM spending sp
    JOIN chosen   ch ON ch.artist_name = sp.artist_name
    GROUP BY ch.category
),

pivot AS (                    -- place the two averages side by side
    SELECT
        MAX(CASE WHEN category = 'TOP' THEN avg_spend END) AS avg_top,
        MAX(CASE WHEN category = 'LOW' THEN avg_spend END) AS avg_low
    FROM avg_spending
)

SELECT 
    ABS(avg_top - avg_low) AS abs_difference
FROM pivot;