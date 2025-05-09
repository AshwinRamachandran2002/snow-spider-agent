SELECT
  t."start_year",
  COUNT(*) AS "total_films"
FROM (
  SELECT DISTINCT TRY_TO_NUMBER(REGEXP_REPLACE("year", '[^0-9]', '')) AS "start_year"
  FROM DB_IMDB.DB_IMDB.MOVIE
  WHERE TRY_TO_NUMBER(REGEXP_REPLACE("year", '[^0-9]', '')) IS NOT NULL
) t
JOIN DB_IMDB.DB_IMDB.MOVIE m ON
  TRY_TO_NUMBER(REGEXP_REPLACE(m."year", '[^0-9]', '')) BETWEEN t."start_year" AND t."start_year" + 9
GROUP BY t."start_year"
ORDER BY "total_films" DESC NULLS LAST
LIMIT 1;