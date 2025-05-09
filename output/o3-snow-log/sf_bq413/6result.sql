SELECT DISTINCT
       COALESCE(
           p."journal":"title"::STRING,
           p."proceedings_title":"preferred"::STRING,
           p."proceedings_title"::STRING,
           p."book_title":"preferred"::STRING,
           p."book_title"::STRING,
           p."book_series_title":"preferred"::STRING,
           p."book_series_title"::STRING
       ) AS "venue_title"
FROM DIMENSIONS_AI_COVID19.DIMENSIONS_AI_COVID19."PUBLICATIONS"        p,
     LATERAL FLATTEN(input => p."research_orgs")                       f
JOIN (SELECT g."id"
      FROM   DIMENSIONS_AI_COVID19.DIMENSIONS_AI_COVID19."GRID" g
      WHERE  LOWER(g."address":"city"::STRING) = 'qianjiang')          g
  ON  f.value::STRING = g."id"
WHERE p."date_inserted" >= 1609459200000000        -- 2021-01-01 UTC (µs)
  AND COALESCE(
           p."journal":"title"::STRING,
           p."proceedings_title":"preferred"::STRING,
           p."proceedings_title"::STRING,
           p."book_title":"preferred"::STRING,
           p."book_title"::STRING,
           p."book_series_title":"preferred"::STRING,
           p."book_series_title"::STRING
       ) IS NOT NULL
ORDER BY "venue_title";