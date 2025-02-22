-- Task: List the name of the best-selling artist.
SELECT a."Name"
FROM CHINOOK.CHINOOK.ARTISTS a
JOIN CHINOOK.CHINOOK.ALBUMS al ON a."ArtistId" = al."ArtistId"
JOIN CHINOOK.CHINOOK.TRACKS t ON al."AlbumId" = t."AlbumId"
JOIN CHINOOK.CHINOOK.INVOICE_ITEMS ii ON t."TrackId" = ii."TrackId"
GROUP BY a."ArtistId", a."Name"
ORDER BY SUM(ii."UnitPrice" * ii."Quantity") DESC NULLS LAST
LIMIT 1;