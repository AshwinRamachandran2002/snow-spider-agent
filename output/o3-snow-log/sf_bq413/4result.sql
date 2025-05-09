SELECT DISTINCT
       venue_title
FROM (
        SELECT
               COALESCE(
                        p."journal":"title",
                        p."proceedings_title",
                        p."book_title",
                        p."book_series_title"
                       )::STRING                         AS venue_title
        FROM "DIMENSIONS_AI_COVID19"."DIMENSIONS_AI_COVID19"."PUBLICATIONS"  p
        ,    LATERAL FLATTEN(input => p."research_orgs")                     org          -- extracts each GRID id
        JOIN "DIMENSIONS_AI_COVID19"."DIMENSIONS_AI_COVID19"."GRID"          g
              ON g."id" = org.value::STRING
        WHERE p."date_inserted" >= 1609459200000000                           -- 2021-01-01 in µs since epoch
          AND LOWER(g."address":"city"::STRING) = 'qianjiang'
     ) sub
WHERE venue_title IS NOT NULL;