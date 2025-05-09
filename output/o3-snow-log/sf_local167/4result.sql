WITH female_legislators AS (
    SELECT "id_bioguide" AS id_bioguide
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS
    WHERE "gender" = 'F'
),
female_terms AS (
    SELECT  lt."id_bioguide"        AS id_bioguide,
            TO_DATE(lt."term_start") AS term_start,
            TO_DATE(lt."term_end")   AS term_end,
            lt."state"               AS state
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS lt
    JOIN female_legislators fl
          ON fl.id_bioguide = lt."id_bioguide"
),
dec31_in_term AS (
    SELECT DISTINCT id_bioguide
    FROM (
        SELECT  id_bioguide,
                term_start,
                term_end,
                CASE
                    WHEN MONTH(term_start) < 12 
                         OR (MONTH(term_start) = 12 AND DAY(term_start) <= 31)
                         THEN DATE_FROM_PARTS(YEAR(term_start), 12, 31)
                    ELSE DATE_FROM_PARTS(YEAR(term_start) + 1, 12, 31)
                END AS dec31_candidate
        FROM female_terms
    ) x
    WHERE dec31_candidate <= term_end
),
first_state AS (
    SELECT  id_bioguide,
            state,
            ROW_NUMBER() OVER (PARTITION BY id_bioguide ORDER BY term_start) AS rn
    FROM female_terms
),
first_state_filtered AS (
    SELECT id_bioguide,
           state
    FROM first_state
    WHERE rn = 1
),
eligible_female_states AS (
    SELECT fs.state
    FROM first_state_filtered fs
    JOIN dec31_in_term d31
      ON fs.id_bioguide = d31.id_bioguide
)
SELECT      state AS state_abbreviation,
            COUNT(*) AS female_legislator_count
FROM        eligible_female_states
GROUP BY    state
ORDER BY    female_legislator_count DESC NULLS LAST
LIMIT 1;