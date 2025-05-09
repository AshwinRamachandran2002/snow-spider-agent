WITH female_legislators AS (
    SELECT "id_bioguide"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS
    WHERE UPPER("gender") = 'F'
),
dec31_terms AS (
    /* legislators whose ANY term spans a December 31 */
    SELECT DISTINCT "id_bioguide"
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS
    WHERE TRY_TO_DATE("term_end") 
          >= DATE_FROM_PARTS(YEAR(TRY_TO_DATE("term_start")), 12, 31)
),
eligible_legislators AS (
    /* female legislators meeting the Dec-31 condition */
    SELECT f."id_bioguide"
    FROM female_legislators f
    JOIN dec31_terms d
      ON f."id_bioguide" = d."id_bioguide"
),
first_state_per_legislator AS (
    /* determine the state of the FIRST term each eligible legislator served */
    SELECT 
        t."id_bioguide",
        t."state",
        ROW_NUMBER() OVER (
            PARTITION BY t."id_bioguide"
            ORDER BY TRY_TO_DATE(t."term_start")
        ) AS rn
    FROM CITY_LEGISLATION.CITY_LEGISLATION.LEGISLATORS_TERMS t
    JOIN eligible_legislators e
      ON t."id_bioguide" = e."id_bioguide"
)
SELECT 
    "state" AS state_abbreviation,
    COUNT(*) AS female_legislator_count
FROM first_state_per_legislator
WHERE rn = 1                             -- keep only the first-represented state
GROUP BY "state"
ORDER BY female_legislator_count DESC NULLS LAST
LIMIT 1;