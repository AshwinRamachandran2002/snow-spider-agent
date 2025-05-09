WITH valid_years AS (
  SELECT TO_NUMBER("year") AS "year_num"
  FROM DB_IMDB.DB_IMDB.MOVIE
  WHERE TRY_TO_NUMBER("year") IS NOT NULL
),
yearly_counts AS (
  SELECT "year_num" AS "start_year", COUNT(*) AS "movie_count"
  FROM valid_years
  GROUP BY "year_num"
),
ten_year_totals AS (
  SELECT
    "start_year",
    SUM("movie_count") OVER (
      ORDER BY "start_year"
      ROWS BETWEEN CURRENT ROW AND 9 FOLLOWING
    ) AS "total_films_in_ten_years"
  FROM yearly_counts
)
SELECT
  "start_year" AS "Start_Year",
  "total_films_in_ten_years" AS "Total_Films"
FROM ten_year_totals
ORDER BY "Total_Films" DESC NULLS LAST
LIMIT 1;