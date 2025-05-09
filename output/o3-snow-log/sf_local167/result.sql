WITH female_legislators AS (            -- all female legislators
    SELECT "id_bioguide" AS id_bioguide
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS
    WHERE UPPER("gender") = 'F'
),
terms AS (                               -- every term with parsed dates
    SELECT 
        "id_bioguide" AS id_bioguide,
        TRY_TO_DATE("term_start") AS term_start_date,
        TRY_TO_DATE("term_end")   AS term_end_date,
        "state"                   AS state
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS
    WHERE TRY_TO_DATE("term_start") IS NOT NULL
      AND TRY_TO_DATE("term_end")   IS NOT NULL
),
dec31_legislators AS (                   -- female legislators with any term covering Dec-31
    SELECT DISTINCT t.id_bioguide
    FROM terms t
    WHERE t.term_end_date >= DATE_FROM_PARTS(YEAR(t.term_start_date), 12, 31)
),
first_state AS (                         -- state of the very first term for each legislator
    SELECT id_bioguide, state AS first_state
    FROM (
        SELECT 
            t.id_bioguide,
            t.state,
            t.term_start_date,
            ROW_NUMBER() OVER (PARTITION BY t.id_bioguide 
                               ORDER BY t.term_start_date) AS rn
        FROM terms t
    ) sub
    WHERE rn = 1
)
SELECT 
    fs.first_state          AS "state_abbrev",
    COUNT(*)                AS "female_legislator_count"
FROM female_legislators fl
JOIN dec31_legislators dl ON fl.id_bioguide = dl.id_bioguide
JOIN first_state      fs ON fl.id_bioguide = fs.id_bioguide
GROUP BY fs.first_state
ORDER BY "female_legislator_count" DESC NULLS LAST
LIMIT 1;