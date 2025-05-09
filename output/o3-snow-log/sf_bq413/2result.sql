WITH qianjiang_grids AS (
    SELECT "id"
    FROM DIMENSIONS_AI_COVID19.DIMENSIONS_AI_COVID19."GRID"
    WHERE LOWER(("address":city)::string) = 'qianjiang'
),
pubs AS (
    SELECT DISTINCT
           COALESCE(
               p."journal":title::string,
               p."proceedings_title":preferred::string,
               p."book_title":preferred::string,
               p."book_series_title":preferred::string
           ) AS "venue_title"
    FROM DIMENSIONS_AI_COVID19.DIMENSIONS_AI_COVID19."PUBLICATIONS" p
    CROSS JOIN LATERAL FLATTEN(input => p."research_orgs") f
    JOIN qianjiang_grids q
      ON q."id" = f.value::string
    WHERE p."date_inserted" >= 1609459200000000   -- 2021-01-01 in microseconds
)
SELECT DISTINCT "venue_title"
FROM pubs
WHERE "venue_title" IS NOT NULL;