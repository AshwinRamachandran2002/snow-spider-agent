WITH female_legislators AS (       -- all female legislators
    SELECT "id_bioguide"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS
    WHERE "gender" = 'F'
),
terms AS (                         -- terms with proper date casting
    SELECT 
        "id_bioguide",
        TO_DATE("term_start") AS term_start,
        TO_DATE("term_end")   AS term_end,
        "state"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS
    WHERE "term_start" IS NOT NULL 
      AND "term_end"   IS NOT NULL
),
terms_dec31_flag AS (              -- flag terms that include a Dec-31
    SELECT 
        t.*,
        CASE
            WHEN term_start <= TO_DATE(CONCAT(YEAR(term_end), '-12-31'))
             AND term_end   >= TO_DATE(CONCAT(YEAR(term_end), '-12-31'))
            THEN 1 ELSE 0 
        END AS includes_dec31
    FROM terms t
),
eligible_legislators AS (          -- female legislators with ≥1 term spanning Dec-31
    SELECT DISTINCT td."id_bioguide"
    FROM terms_dec31_flag td
    JOIN female_legislators fl USING("id_bioguide")
    WHERE td.includes_dec31 = 1
),
first_state_per_legislator AS (    -- the first state each eligible legislator represented
    SELECT 
        td."id_bioguide",
        td."state",
        ROW_NUMBER() OVER (PARTITION BY td."id_bioguide" ORDER BY td.term_start) AS rn
    FROM terms_dec31_flag td
    JOIN eligible_legislators el USING("id_bioguide")
)
SELECT 
    "state"          AS state_abbreviation,
    COUNT(*)         AS female_legislators_count
FROM first_state_per_legislator
WHERE rn = 1                       -- keep only the earliest state per legislator
GROUP BY "state"
ORDER BY female_legislators_count DESC NULLS LAST
LIMIT 1;