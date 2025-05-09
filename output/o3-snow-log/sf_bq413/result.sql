WITH pubs AS (
    SELECT 
        p."id",
        p."journal",
        p."proceedings_title",
        p."book_title",
        p."book_series_title",
        f.value::string AS "grid_id"
    FROM DIMENSIONS_AI_COVID19.DIMENSIONS_AI_COVID19.PUBLICATIONS AS p
         , LATERAL FLATTEN(input => p."research_orgs") AS f
    WHERE p."date_inserted" >= 1609459200000000      -- 2021-01-01 in microseconds
),
grids AS (
    SELECT 
        g."id"
    FROM DIMENSIONS_AI_COVID19.DIMENSIONS_AI_COVID19.GRID AS g
    WHERE g."address":"city"::string = 'Qianjiang'
)
SELECT DISTINCT
    COALESCE(
        pubs."journal":"title"::string,
        pubs."proceedings_title":"title"::string,
        pubs."book_title":"title"::string,
        pubs."book_series_title":"title"::string
    ) AS "venue_title"
FROM pubs
JOIN grids
  ON pubs."grid_id" = grids."id"
WHERE COALESCE(
        pubs."journal":"title"::string,
        pubs."proceedings_title":"title"::string,
        pubs."book_title":"title"::string,
        pubs."book_series_title":"title"::string
      ) IS NOT NULL;