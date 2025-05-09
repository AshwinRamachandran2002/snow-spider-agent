WITH earliest_pub AS (   -- earliest publication for every application
    SELECT
        pub."publication_number",
        pub."application_number",
        pub."publication_date",
        ROW_NUMBER() OVER (
            PARTITION BY pub."application_number"
            ORDER BY pub."publication_date"
        ) AS "rn"
    FROM PATENTS_USPTO.PATENTS.PUBLICATIONS pub
),
ind_claims AS (          -- independent-claim word counts
    SELECT
        pcs."pat_no",
        pcs."claim_no",
        CAST(pcs."word_ct" AS INT)  AS "word_ct"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_CLAIMS_STATS pcs
    WHERE pcs."ind_flg" = '1'
)
SELECT
    ep."publication_number",
    ep."application_number",
    ic."claim_no",
    ic."word_ct"
FROM ind_claims               ic
JOIN PATENTS_USPTO.USPTO_OCE_CLAIMS.MATCH  m   ON ic."pat_no" = m."pat_no"
JOIN earliest_pub                        ep  ON m."publication_number" = ep."publication_number"
WHERE ep."rn" = 1                         -- keep only earliest pub per application
ORDER BY ic."word_ct" DESC NULLS LAST
LIMIT 100;