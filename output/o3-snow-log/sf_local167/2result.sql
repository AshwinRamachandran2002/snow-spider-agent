WITH female_terms AS (       -- all terms served by female legislators
    SELECT
        l."id_bioguide"          AS id_bioguide,
        t."state"                AS state,
        TO_DATE(t."term_start")  AS term_start,
        TO_DATE(t."term_end")    AS term_end
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS        l
    JOIN CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS  t
          ON l."id_bioguide" = t."id_bioguide"
    WHERE l."gender" = 'F'
),
dec31_terms AS (              -- identify terms that ever include Dec-31
    SELECT
        *,
        CASE
             WHEN YEAR(term_end) >  YEAR(term_start)
                  OR term_end >= DATE_FROM_PARTS(YEAR(term_start),12,31)
             THEN 1 ELSE 0
        END AS includes_dec31
    FROM female_terms
),
first_state AS (              -- first state each female legislator served
    SELECT DISTINCT
        id_bioguide,
        FIRST_VALUE(state) OVER (PARTITION BY id_bioguide
                                 ORDER BY term_start) AS first_state
    FROM female_terms
),
eligible_legislators AS (     -- female legislators with a Dec-31 term
    SELECT DISTINCT id_bioguide
    FROM dec31_terms
    WHERE includes_dec31 = 1
)
SELECT
    fs.first_state      AS state_abbrev,
    COUNT(*)            AS female_legislator_count
FROM first_state              fs
JOIN eligible_legislators     el
  ON fs.id_bioguide = el.id_bioguide
GROUP BY fs.first_state
ORDER BY female_legislator_count DESC NULLS LAST
LIMIT 1;