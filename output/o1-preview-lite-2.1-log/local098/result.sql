SELECT COUNT(DISTINCT sub."PID") AS Number_of_Actors
FROM (
  SELECT sub1."PID", MAX(sub1.year_gap) AS max_gap
  FROM (
    SELECT
      mc."PID",
      CAST(SUBSTR(m."year", -4, 4) AS INTEGER) AS year_num,
      CAST(SUBSTR(m."year", -4, 4) AS INTEGER) - LAG(CAST(SUBSTR(m."year", -4, 4) AS INTEGER)) OVER (
        PARTITION BY mc."PID"
        ORDER BY CAST(SUBSTR(m."year", -4, 4) AS INTEGER)
      ) AS year_gap
    FROM "M_Cast" mc
    JOIN "Movie" m ON mc."MID" = m."MID"
    WHERE
      m."year" IS NOT NULL
      AND LENGTH(SUBSTR(m."year", -4, 4)) = 4
      AND CAST(SUBSTR(m."year", -4, 4) AS INTEGER) BETWEEN 1900 AND 2100
  ) sub1
  GROUP BY sub1."PID"
  HAVING MAX(year_gap) <= 3 OR MAX(year_gap) IS NULL
) sub;