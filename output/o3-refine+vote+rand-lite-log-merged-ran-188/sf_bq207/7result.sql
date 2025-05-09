WITH ind_claims AS (   -- independent-claim stats with numeric word counts
    SELECT
        pcs."pat_no",
        TRY_TO_NUMBER(pcs."word_ct")      AS "word_ct_num",
        pcs."claim_no"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_CLAIMS_STATS pcs
    WHERE pcs."ind_flg" = '1'
          AND pcs."word_ct" IS NOT NULL
),
pub_map AS (           -- map patents to their DOCDB publication numbers
    SELECT
        m."pat_no",
        m."publication_number"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.MATCH m
    WHERE m."publication_number" IS NOT NULL
),
pubs AS (              -- basic publication info
    SELECT
        p."publication_number",
        p."application_number",
        p."publication_date"
    FROM PATENTS_USPTO.PATENTS.PUBLICATIONS p
),
earliest_per_app AS (  -- earliest publication date for each application
    SELECT
        "application_number",
        MIN("publication_date") AS "earliest_pub_date"
    FROM pubs
    GROUP BY "application_number"
),
earliest_pubs AS (     -- retain only the earliest publication record per application
    SELECT
        pub."publication_number",
        pub."application_number"
    FROM pubs             AS pub
    JOIN earliest_per_app AS ea
      ON ea."application_number" = pub."application_number"
     AND ea."earliest_pub_date" = pub."publication_date"
)
SELECT
    ep."publication_number",
    ep."application_number",
    ic."claim_no",
    ic."word_ct_num"      AS "word_ct"
FROM ind_claims      AS ic
JOIN pub_map         AS pm  ON pm."pat_no"           = ic."pat_no"
JOIN earliest_pubs   AS ep  ON ep."publication_number" = pm."publication_number"
ORDER BY ic."word_ct_num" DESC NULLS LAST
LIMIT 100;