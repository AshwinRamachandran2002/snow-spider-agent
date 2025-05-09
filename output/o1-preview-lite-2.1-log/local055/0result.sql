WITH
best_selling_artist AS (
    SELECT ar."ArtistId"
    FROM "artists" ar
    JOIN "albums" al ON ar."ArtistId" = al."ArtistId"
    JOIN "tracks" t ON al."AlbumId" = t."AlbumId"
    JOIN "invoice_items" ii ON t."TrackId" = ii."TrackId"
    GROUP BY ar."ArtistId"
    ORDER BY SUM(ii."Quantity") DESC, ar."Name" ASC
    LIMIT 1
),
least_selling_artist AS (
    SELECT ar."ArtistId"
    FROM "artists" ar
    JOIN "albums" al ON ar."ArtistId" = al."ArtistId"
    JOIN "tracks" t ON al."AlbumId" = t."AlbumId"
    JOIN "invoice_items" ii ON t."TrackId" = ii."TrackId"
    GROUP BY ar."ArtistId"
    HAVING SUM(ii."Quantity") > 0
    ORDER BY SUM(ii."Quantity") ASC, ar."Name" ASC
    LIMIT 1
),
customers_best AS (
    SELECT DISTINCT c."CustomerId"
    FROM "customers" c
    JOIN "invoices" i ON c."CustomerId" = i."CustomerId"
    JOIN "invoice_items" ii ON i."InvoiceId" = ii."InvoiceId"
    JOIN "tracks" t ON ii."TrackId" = t."TrackId"
    JOIN "albums" al ON t."AlbumId" = al."AlbumId"
    WHERE al."ArtistId" IN (SELECT "ArtistId" FROM best_selling_artist)
),
customers_least AS (
    SELECT DISTINCT c."CustomerId"
    FROM "customers" c
    JOIN "invoices" i ON c."CustomerId" = i."CustomerId"
    JOIN "invoice_items" ii ON i."InvoiceId" = ii."InvoiceId"
    JOIN "tracks" t ON ii."TrackId" = t."TrackId"
    JOIN "albums" al ON t."AlbumId" = al."AlbumId"
    WHERE al."ArtistId" IN (SELECT "ArtistId" FROM least_selling_artist)
),
avg_spending_best AS (
    SELECT AVG(i."Total") AS "avg_spending"
    FROM "invoices" i
    WHERE i."CustomerId" IN (SELECT "CustomerId" FROM customers_best)
),
avg_spending_least AS (
    SELECT AVG(i."Total") AS "avg_spending"
    FROM "invoices" i
    WHERE i."CustomerId" IN (SELECT "CustomerId" FROM customers_least)
)
SELECT printf("%.4f", ABS(
    (SELECT "avg_spending" FROM avg_spending_best) -
    (SELECT "avg_spending" FROM avg_spending_least)
)) AS "difference_in_average_spending";