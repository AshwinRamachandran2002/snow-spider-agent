WITH independent_claims AS (   -- all independent claims
    SELECT
        pcs."pat_no",
        TO_NUMBER(pcs."word_ct")            AS "word_ct",
        pcs."claim_no",
        m."publication_number"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS."PATENT_CLAIMS_STATS"  pcs
    JOIN PATENTS_USPTO.USPTO_OCE_CLAIMS."MATCH"                m
          ON pcs."pat_no" = m."pat_no"
    WHERE pcs."ind_flg" = '1'
),
claims_with_pub AS (           -- attach publication & application data
    SELECT
        ic."publication_number",
        p."application_number",
        ic."claim_no",
        ic."word_ct",
        p."publication_date",
        ROW_NUMBER() OVER (                     -- keep earliest pub per application
            PARTITION BY p."application_number"
            ORDER BY p."publication_date" ASC,
                     ic."word_ct"      DESC,
                     TO_NUMBER(ic."claim_no") ASC
        ) AS rn
    FROM independent_claims                ic
    JOIN PATENTS_USPTO.PATENTS."PUBLICATIONS"  p
         ON p."publication_number" = ic."publication_number"
)
SELECT
    "publication_number"  AS "earliest_publication_number",
    "application_number",
    "claim_no",
    "word_ct"
FROM claims_with_pub
WHERE rn = 1                                   -- earliest pub for each application
ORDER BY "word_ct" DESC NULLS LAST             -- top 100 longest claims
LIMIT 100;