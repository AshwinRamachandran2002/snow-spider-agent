WITH female_legislators AS (          -- all female legislators
    SELECT "id_bioguide"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS
    WHERE UPPER("gender") = 'F'
),  
terms_including_dec_31 AS (          -- legislators whose *any* term covered Dec-31
    SELECT DISTINCT "id_bioguide"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS
    WHERE TO_DATE("term_end") >= DATE_FROM_PARTS( YEAR( TO_DATE("term_start") ), 12, 31 )
),  
eligible_legislators AS (            -- female + had a term including Dec-31
    SELECT fl."id_bioguide"
    FROM female_legislators fl
    JOIN terms_including_dec_31 t 
          ON fl."id_bioguide" = t."id_bioguide"
),  
first_state_per_legislator AS (      -- the state from the earliest term for each eligible legislator
    SELECT 
        lt."id_bioguide",
        lt."state",
        ROW_NUMBER() OVER (PARTITION BY lt."id_bioguide" 
                           ORDER BY TO_DATE(lt."term_start")) AS rn
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS lt
    JOIN eligible_legislators el 
          ON lt."id_bioguide" = el."id_bioguide"
)
SELECT 
    "state"      AS "state_abbreviation",
    COUNT(*)     AS "female_legislators_count"
FROM first_state_per_legislator
WHERE rn = 1                              -- only their first-represented state
GROUP BY "state"
ORDER BY "female_legislators_count" DESC NULLS LAST
LIMIT 1;