WITH artist_sales AS (
    /* total sales (revenue) for every artist                           */
    SELECT  ar."ArtistId",
            ar."Name",
            COALESCE(SUM(ii."UnitPrice" * ii."Quantity"),0) AS TotalSales
    FROM    artists        ar
    LEFT JOIN albums       al ON al."ArtistId" = ar."ArtistId"
    LEFT JOIN tracks       t  ON t."AlbumId"   = al."AlbumId"
    LEFT JOIN invoice_items ii ON ii."TrackId" = t."TrackId"
    GROUP BY ar."ArtistId", ar."Name"
),
/* the best‑selling artist (highest sales, tie → alphabetical)          */
top_artist AS (
    SELECT "ArtistId" AS TopArtistId
    FROM   artist_sales
    ORDER  BY TotalSales DESC, "Name" ASC
    LIMIT  1
),
/* the worst‑selling artist (lowest sales, tie → alphabetical)          */
bottom_artist AS (
    SELECT "ArtistId" AS BottomArtistId
    FROM   artist_sales
    ORDER  BY TotalSales ASC, "Name" ASC
    LIMIT  1
),
/* per‑customer spending on only those two artists                      */
customer_spend AS (
    SELECT  c."CustomerId",
            SUM(CASE WHEN art."ArtistId" = (SELECT TopArtistId FROM top_artist)
                     THEN ii."UnitPrice" * ii."Quantity" ELSE 0 END) AS TopSpend,
            SUM(CASE WHEN art."ArtistId" = (SELECT BottomArtistId FROM bottom_artist)
                     THEN ii."UnitPrice" * ii."Quantity" ELSE 0 END) AS BottomSpend
    FROM    customers      c
    LEFT JOIN invoices     inv ON inv."CustomerId" = c."CustomerId"
    LEFT JOIN invoice_items ii  ON ii."InvoiceId"  = inv."InvoiceId"
    LEFT JOIN tracks       t    ON t."TrackId"     = ii."TrackId"
    LEFT JOIN albums       al   ON al."AlbumId"    = t."AlbumId"
    LEFT JOIN artists      art  ON art."ArtistId"  = al."ArtistId"
    GROUP BY c."CustomerId"
),
/* average spend for customers who bought from each artist              */
avg_spend AS (
    SELECT  COALESCE((SELECT AVG(TopSpend)
                      FROM   customer_spend
                      WHERE  TopSpend  > 0),0) AS AvgTop,
            COALESCE((SELECT AVG(BottomSpend)
                      FROM   customer_spend
                      WHERE  BottomSpend > 0),0) AS AvgBottom
)
/* absolute difference, rounded to four decimals                        */
SELECT ROUND(ABS(AvgTop - AvgBottom),4) AS Difference
FROM   avg_spend;