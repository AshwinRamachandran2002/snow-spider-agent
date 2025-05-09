WITH independent_claims AS (   -- all independent claims with a word‑count
    SELECT
        pcs."pat_no",
        pcs."claim_no",
        CAST(pcs."word_ct" AS INTEGER)   AS word_count
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS."PATENT_CLAIMS_STATS" pcs
    WHERE pcs."ind_flg" = '1'
      AND pcs."word_ct" IS NOT NULL
),                                                             
matched_to_pubs AS (         -- add DOCDB publication number via the match table
    SELECT
        ic.*,
        m."publication_number"
    FROM independent_claims ic
    JOIN PATENTS_USPTO.USPTO_OCE_CLAIMS."MATCH" m
          ON ic."pat_no" = m."pat_no"
),                                                              
pubs_with_app AS (           -- pull application number & pub‑date
    SELECT
        mp."pat_no",
        mp."claim_no",
        mp.word_count,
        mp."publication_number",
        p."application_number",
        p."publication_date"
    FROM matched_to_pubs mp
    JOIN PATENTS_USPTO.PATENTS."PUBLICATIONS" p
          ON p."publication_number" = mp."publication_number"
),                                                              
earliest_pub_per_app AS (    -- compute earliest publication for each application
    SELECT
        e."application_number",
        e."publication_number"
    FROM (
        SELECT
            p."application_number",
            p."publication_number",
            p."publication_date",
            ROW_NUMBER() OVER (PARTITION BY p."application_number"
                               ORDER BY p."publication_date" ASC) AS rn
        FROM PATENTS_USPTO.PATENTS."PUBLICATIONS" p
        WHERE p."application_number" IS NOT NULL
    ) e
    WHERE e.rn = 1            -- keep only the earliest
),                                                              
claims_earliest_pub AS (     -- keep only rows that correspond to earliest pub
    SELECT
        pw."publication_number",
        pw."application_number",
        pw."claim_no",
        pw.word_count
    FROM pubs_with_app pw
    JOIN earliest_pub_per_app ep
          ON ep."application_number"   = pw."application_number"
         AND ep."publication_number"   = pw."publication_number"
)                                                               
SELECT
    "publication_number",
    "application_number",
    "claim_no",
    word_count
FROM claims_earliest_pub
ORDER BY word_count DESC NULLS LAST, "publication_number"
LIMIT 100;