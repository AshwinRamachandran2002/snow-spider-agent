SELECT
  Start_year,
  Total_films
FROM (
  WITH ValidMovies AS (
    SELECT
      CAST(SUBSTR("year", -4, 4) AS INTEGER) AS year_num
    FROM
      "Movie"
    WHERE
      SUBSTR("year", -4, 4) GLOB '[0-9][0-9][0-9][0-9]'
      AND CAST(SUBSTR("year", -4, 4) AS INTEGER) BETWEEN 1900 AND 2023
  ),
  MovieCounts AS (
    SELECT
      year_num,
      COUNT(*) AS num_movies
    FROM
      ValidMovies
    GROUP BY
      year_num
  ),
  StartYears AS (
    SELECT DISTINCT year_num AS start_year
    FROM ValidMovies
    WHERE year_num <= (SELECT MAX(year_num) - 9 FROM ValidMovies)
  )
  SELECT
    StartYears.start_year AS Start_year,
    SUM(MovieCounts.num_movies) AS Total_films
  FROM
    StartYears
  JOIN
    MovieCounts
    ON MovieCounts.year_num BETWEEN StartYears.start_year AND StartYears.start_year + 9
  GROUP BY
    StartYears.start_year
)
ORDER BY
  Total_films DESC
LIMIT 1;