WITH independent_claims AS (
    /*  all independent patent-claims with their word counts                */
    SELECT
        pcs."pat_no",                       -- granted-patent number
        pcs."claim_no",                     -- claim id
        CAST(pcs."word_ct" AS INTEGER) 
            AS "word_ct",                   -- word count (numeric)
        m."publication_number"              -- formatted publication number
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_CLAIMS_STATS  pcs
    JOIN PATENTS_USPTO.USPTO_OCE_CLAIMS.MATCH                m
          ON pcs."pat_no" = m."pat_no"
    WHERE pcs."ind_flg" = '1'               -- independent claims only
),                                                               
pub_meta AS (
    /*  meta-data of every publication                                      */
    SELECT
        p."publication_number",
        p."application_number",
        p."publication_date"
    FROM PATENTS_USPTO.PATENTS.PUBLICATIONS p
),                                                                
earliest_pub AS (
    /*  earliest publication (smallest date) for each application           */
    SELECT
        "application_number",
        MIN("publication_date") AS min_pub_date
    FROM pub_meta
    GROUP BY "application_number"
),                                                                
earliest_ind_claims AS (
    /*  keep only claims that belong to that earliest publication            */
    SELECT
        ic."publication_number",
        pm."application_number",
        ic."claim_no",
        ic."word_ct"
    FROM independent_claims          ic
    JOIN pub_meta                   pm
          ON ic."publication_number" = pm."publication_number"
    JOIN earliest_pub               ep
          ON     pm."application_number" = ep."application_number"
             AND pm."publication_date"   = ep.min_pub_date
)                                                                
SELECT
    "publication_number",
    "application_number",
    "claim_no",
    "word_ct"
FROM earliest_ind_claims
ORDER BY "word_ct" DESC NULLS LAST
LIMIT 100;