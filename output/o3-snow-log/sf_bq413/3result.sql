SELECT DISTINCT
       COALESCE(
           p."journal":"title"::string,
           p."proceedings_title"::string,
           p."book_title"::string,
           p."book_series_title"::string
       ) AS "venue_title"
FROM DIMENSIONS_AI_COVID19.DIMENSIONS_AI_COVID19.PUBLICATIONS      AS p,
     LATERAL FLATTEN(input => p."research_orgs")                   AS f
JOIN DIMENSIONS_AI_COVID19.DIMENSIONS_AI_COVID19.GRID              AS g
     ON f.value::string = g."id"
WHERE p."date_inserted" >= 1609459200000000              -- 2021-01-01 00:00:00 UTC in µs
  AND LOWER(g."address":"city"::string) = 'qianjiang'
  AND COALESCE(
        p."journal":"title"::string,
        p."proceedings_title"::string,
        p."book_title"::string,
        p."book_series_title"::string
      ) IS NOT NULL;