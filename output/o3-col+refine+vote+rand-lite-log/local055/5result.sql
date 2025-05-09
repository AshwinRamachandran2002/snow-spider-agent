WITH artist_totals AS (          -- total dollars sold by every artist
    SELECT ar."ArtistId",
           ar."Name",
           COALESCE(SUM(ii."UnitPrice" * ii."Quantity"),0) AS total_sales
    FROM   "artists"        ar
    LEFT   JOIN "albums"         al ON ar."ArtistId" = al."ArtistId"
    LEFT   JOIN "tracks"         tr ON al."AlbumId"  = tr."AlbumId"
    LEFT   JOIN "invoice_items"  ii ON tr."TrackId"  = ii."TrackId"
    GROUP  BY ar."ArtistId"
),
top_artist AS (                 -- highest-selling artist  (tie → alphabetically)
    SELECT "ArtistId"
    FROM   artist_totals
    ORDER  BY total_sales DESC, "Name" ASC
    LIMIT  1
),
bottom_artist AS (              -- lowest-selling artist  (tie → alphabetically)
    SELECT "ArtistId"
    FROM   artist_totals
    ORDER  BY total_sales ASC,  "Name" ASC
    LIMIT  1
),
top_spend_per_customer AS (     -- what each customer spent on the top artist
    SELECT cu."CustomerId",
           SUM(ii."UnitPrice" * ii."Quantity") AS spend
    FROM   "customers"       cu
    JOIN   "invoices"        inv ON cu."CustomerId" = inv."CustomerId"
    JOIN   "invoice_items"   ii  ON inv."InvoiceId" = ii."InvoiceId"
    JOIN   "tracks"          tr  ON ii."TrackId"    = tr."TrackId"
    JOIN   "albums"          al  ON tr."AlbumId"    = al."AlbumId"
    WHERE  al."ArtistId" = (SELECT "ArtistId" FROM top_artist)
    GROUP  BY cu."CustomerId"
),
bottom_spend_per_customer AS (  -- what each customer spent on the bottom artist
    SELECT cu."CustomerId",
           SUM(ii."UnitPrice" * ii."Quantity") AS spend
    FROM   "customers"       cu
    JOIN   "invoices"        inv ON cu."CustomerId" = inv."CustomerId"
    JOIN   "invoice_items"   ii  ON inv."InvoiceId" = ii."InvoiceId"
    JOIN   "tracks"          tr  ON ii."TrackId"    = tr."TrackId"
    JOIN   "albums"          al  ON tr."AlbumId"    = al."AlbumId"
    WHERE  al."ArtistId" = (SELECT "ArtistId" FROM bottom_artist)
    GROUP  BY cu."CustomerId"
),
top_avg AS (                    -- average spend among customers who bought top artist
    SELECT AVG(spend) AS v FROM top_spend_per_customer
),
bottom_avg AS (                 -- average spend among customers who bought bottom artist
    SELECT AVG(spend) AS v FROM bottom_spend_per_customer
)
SELECT ABS( COALESCE((SELECT v FROM top_avg),0)
          - COALESCE((SELECT v FROM bottom_avg),0) ) AS "absolute_difference";