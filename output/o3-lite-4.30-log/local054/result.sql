WITH best_artist AS (
  SELECT ar."ArtistId"
  FROM "artists" ar
  JOIN "albums"  al ON al."ArtistId" = ar."ArtistId"
  JOIN "tracks"  t  ON t."AlbumId"   = al."AlbumId"
  JOIN "invoice_items" ii ON ii."TrackId" = t."TrackId"
  GROUP BY ar."ArtistId"
  ORDER BY SUM(ii."UnitPrice" * ii."Quantity") DESC
  LIMIT 1
)
SELECT
  c."FirstName"                                            AS first_name,
  printf('%.4f', SUM(ii."UnitPrice" * ii."Quantity"))      AS amount_spent
FROM "customers"      c
JOIN "invoices"       i  ON i."CustomerId" = c."CustomerId"
JOIN "invoice_items"  ii ON ii."InvoiceId" = i."InvoiceId"
JOIN "tracks"         t  ON t."TrackId"    = ii."TrackId"
JOIN "albums"         al ON al."AlbumId"   = t."AlbumId"
JOIN best_artist      ba ON ba."ArtistId"  = al."ArtistId"
GROUP BY c."CustomerId"
HAVING SUM(ii."UnitPrice" * ii."Quantity") < 1
ORDER BY amount_spent DESC, first_name;