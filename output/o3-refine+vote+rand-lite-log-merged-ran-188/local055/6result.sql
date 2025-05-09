WITH artist_sales AS (
  /* total sales for every artist (tracks that have been sold) */
  SELECT ar."ArtistId",
         ar."Name",
         SUM(ii."UnitPrice"*ii."Quantity") AS sales
  FROM   "invoice_items" AS ii
  JOIN   "tracks"        AS t  USING ("TrackId")
  JOIN   "albums"        AS al USING ("AlbumId")
  JOIN   "artists"       AS ar USING ("ArtistId")
  GROUP  BY ar."ArtistId"
),
/* highest-selling artist (tie-break by name A-Z) */
top_artist AS (
  SELECT "ArtistId"
  FROM   artist_sales
  ORDER  BY sales DESC, "Name"
  LIMIT  1
),
/* lowest-selling artist with non-zero sales (tie-break by name A-Z) */
bottom_artist AS (
  SELECT "ArtistId"
  FROM   artist_sales
  WHERE  sales > 0
  ORDER  BY sales ASC, "Name"
  LIMIT  1
),
/* how much each customer spent on those two artists */
cust_spend AS (
  SELECT inv."CustomerId",
         ar."ArtistId",
         SUM(ii."UnitPrice"*ii."Quantity") AS spent
  FROM   "invoice_items" AS ii
  JOIN   "invoices"      AS inv ON inv."InvoiceId" = ii."InvoiceId"
  JOIN   "tracks"        AS t   USING ("TrackId")
  JOIN   "albums"        AS al  USING ("AlbumId")
  JOIN   "artists"       AS ar  USING ("ArtistId")
  WHERE  ar."ArtistId" IN (SELECT "ArtistId" FROM top_artist
                           UNION
                           SELECT "ArtistId" FROM bottom_artist)
  GROUP  BY inv."CustomerId", ar."ArtistId"
),
/* average spending for each of the two artists */
avg_per_artist AS (
  SELECT "ArtistId", AVG(spent) AS avg_spent
  FROM   cust_spend
  GROUP  BY "ArtistId"
)
/* absolute difference between the two averages */
SELECT ABS(
         (SELECT avg_spent FROM avg_per_artist WHERE "ArtistId" = (SELECT "ArtistId" FROM top_artist))
         -
         (SELECT avg_spent FROM avg_per_artist WHERE "ArtistId" = (SELECT "ArtistId" FROM bottom_artist))
       ) AS avg_difference;