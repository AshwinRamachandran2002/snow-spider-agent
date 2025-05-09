WITH revenue_by_artist AS (
    SELECT
        art."ArtistId",
        SUM(ii."UnitPrice" * ii."Quantity") AS artist_revenue
    FROM CHINOOK.CHINOOK.INVOICE_ITEMS    ii
    JOIN CHINOOK.CHINOOK.TRACKS           tr  ON ii."TrackId"   = tr."TrackId"
    JOIN CHINOOK.CHINOOK.ALBUMS           alb ON tr."AlbumId"   = alb."AlbumId"
    JOIN CHINOOK.CHINOOK.ARTISTS          art ON alb."ArtistId" = art."ArtistId"
    GROUP BY art."ArtistId"
),
best_selling_artist AS (
    SELECT "ArtistId"
    FROM revenue_by_artist
    ORDER BY artist_revenue DESC NULLS LAST
    LIMIT 1
),
customer_spend AS (
    SELECT
        cust."CustomerId",
        cust."FirstName",
        SUM(ii."UnitPrice" * ii."Quantity") AS amount_spent
    FROM CHINOOK.CHINOOK.INVOICE_ITEMS ii
    JOIN CHINOOK.CHINOOK.INVOICES      inv  ON ii."InvoiceId" = inv."InvoiceId"
    JOIN CHINOOK.CHINOOK.CUSTOMERS     cust ON inv."CustomerId" = cust."CustomerId"
    JOIN CHINOOK.CHINOOK.TRACKS        tr   ON ii."TrackId" = tr."TrackId"
    JOIN CHINOOK.CHINOOK.ALBUMS        alb  ON tr."AlbumId" = alb."AlbumId"
    WHERE alb."ArtistId" = (SELECT "ArtistId" FROM best_selling_artist)
    GROUP BY cust."CustomerId", cust."FirstName"
)
SELECT
    "FirstName",
    ROUND(amount_spent, 2) AS "AmountSpent"
FROM customer_spend
WHERE amount_spent < 1
ORDER BY amount_spent ASC NULLS LAST, "FirstName";