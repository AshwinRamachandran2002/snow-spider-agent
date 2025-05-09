WITH female_terms AS (   -- all terms for female legislators
    SELECT  l."id_bioguide",
            t."term_start",
            t."term_end",
            t."state"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS             l
    JOIN CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS       t
           ON l."id_bioguide" = t."id_bioguide"
    WHERE l."gender" = 'F'
),

terms_with_dec31 AS (    -- flag terms that ever include a Dec-31
    SELECT  ft.*,
            CASE
                 WHEN YEAR(TO_DATE(ft."term_end"))   >  YEAR(TO_DATE(ft."term_start"))
                      THEN 1
                 WHEN MONTH(TO_DATE(ft."term_end"))  = 12
                  AND DAY(TO_DATE(ft."term_end"))    = 31
                      THEN 1
                 ELSE 0
            END AS "includes_dec31"
    FROM female_terms ft
),

eligible_legislators AS (   -- female legislators with ≥1 such term
    SELECT DISTINCT "id_bioguide"
    FROM terms_with_dec31
    WHERE "includes_dec31" = 1
),

first_state AS (            -- state they first represented
    SELECT  ft."id_bioguide",
            ft."state",
            ROW_NUMBER() OVER (PARTITION BY ft."id_bioguide"
                               ORDER BY TO_DATE(ft."term_start")) AS rn
    FROM female_terms ft
    JOIN eligible_legislators el
          ON ft."id_bioguide" = el."id_bioguide"
)

SELECT  "state"               AS state_abbreviation,
        COUNT(DISTINCT "id_bioguide")  AS female_legislators_count
FROM    first_state
WHERE   rn = 1                -- only the first-represented state per legislator
GROUP BY "state"
ORDER BY female_legislators_count DESC NULLS LAST
LIMIT 1;