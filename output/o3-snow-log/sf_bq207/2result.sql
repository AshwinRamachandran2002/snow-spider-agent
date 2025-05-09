WITH independent_claims AS (   -- independent claims with a word count
    SELECT 
        c."pat_no",
        c."claim_no",
        TRY_TO_NUMBER(c."word_ct") AS "word_ct"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS."PATENT_CLAIMS_STATS"  c
    WHERE c."ind_flg" = '1'
      AND c."word_ct" IS NOT NULL
), claims_with_pub AS (         -- map patents to their publication numbers
    SELECT 
        ic."pat_no",
        ic."claim_no",
        ic."word_ct",
        m."publication_number"
    FROM independent_claims  ic
    JOIN PATENTS_USPTO.USPTO_OCE_CLAIMS."MATCH"  m
          ON ic."pat_no" = m."pat_no"
), claims_with_application AS ( -- pull in application & publication dates
    SELECT
        cp."publication_number",
        p."application_number",
        cp."claim_no",
        cp."word_ct",
        p."publication_date"
    FROM claims_with_pub  cp
    JOIN PATENTS_USPTO.PATENTS."PUBLICATIONS"  p
          ON cp."publication_number" = p."publication_number"
), earliest_pub_per_app AS (    -- keep only the earliest publication in each application family
    SELECT
        ca.*,
        MIN(ca."publication_date") OVER (PARTITION BY ca."application_number") AS "earliest_pub_date"
    FROM claims_with_application  ca
)
SELECT
    "publication_number",
    "application_number",
    "claim_no",
    "word_ct"
FROM earliest_pub_per_app
WHERE "publication_date" = "earliest_pub_date"
ORDER BY "word_ct" DESC NULLS LAST
LIMIT 100;