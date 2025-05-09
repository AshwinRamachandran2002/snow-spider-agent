SELECT DISTINCT
       COALESCE( p."journal":"title"::string,
                 p."proceedings_title":"preferred"::string,
                 p."proceedings_title"::string,
                 p."book_title":"preferred"::string,
                 p."book_title"::string,
                 p."book_series_title":"preferred"::string,
                 p."book_series_title"::string) AS "venue_title"
FROM DIMENSIONS_AI_COVID19.DIMENSIONS_AI_COVID19.PUBLICATIONS AS p,
     LATERAL FLATTEN(input => p."research_orgs") AS f
JOIN DIMENSIONS_AI_COVID19.DIMENSIONS_AI_COVID19.GRID AS g
     ON g."id" = f.value::string
WHERE g."address":"city"::string = 'Qianjiang'
  AND TO_TIMESTAMP(p."date_inserted" / 1000000) >= '2021-01-01'
  AND COALESCE( p."journal":"title"::string,
                p."proceedings_title":"preferred"::string,
                p."proceedings_title"::string,
                p."book_title":"preferred"::string,
                p."book_title"::string,
                p."book_series_title":"preferred"::string,
                p."book_series_title"::string) IS NOT NULL;