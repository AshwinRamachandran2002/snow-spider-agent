SELECT
       1960 + 5 * FLOOR( (FLOOR("publication_date" / 10000) - 1960) / 5 )                         AS "bucket_start_year",
       1960 + 5 * FLOOR( (FLOOR("publication_date" / 10000) - 1960) / 5 ) + 4                   AS "bucket_end_year",
       COUNT(*)                                                                                 AS "total_publications",
       ROUND(AVG(ARRAY_SIZE("inventor")), 4)                                                    AS "avg_inventors_per_publication"
FROM   PATENTS.PATENTS.PUBLICATIONS
WHERE  "country_code" = 'CA'
  AND  "publication_date" BETWEEN 19600101 AND 20201231
  AND  ARRAY_SIZE("inventor") > 0
GROUP  BY "bucket_start_year"
ORDER  BY "bucket_start_year";