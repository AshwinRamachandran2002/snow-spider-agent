SELECT DISTINCT
       COALESCE(
           p."journal":"title"::string,
           p."proceedings_title"::string,
           p."book_title"::string,
           p."book_series_title"::string
       ) AS "venue_title"
FROM DIMENSIONS_AI_COVID19.DIMENSIONS_AI_COVID19.PUBLICATIONS  AS p
CROSS JOIN LATERAL FLATTEN(INPUT => p."research_orgs")          AS r      -- each GRID id linked to the publication
JOIN DIMENSIONS_AI_COVID19.DIMENSIONS_AI_COVID19.GRID           AS g
     ON r.value::string = g."id"
WHERE DATE_PART('year', TO_TIMESTAMP_NTZ(p."date_inserted" / 1000000)) >= 2021   -- inserted in 2021 or later
  AND g."address":"city"::string = 'Qianjiang'                                   -- GRID city is Qianjiang
  AND COALESCE(
          p."journal":"title"::string,
          p."proceedings_title"::string,
          p."book_title"::string,
          p."book_series_title"::string
      ) IS NOT NULL;