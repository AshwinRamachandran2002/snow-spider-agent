WITH independent_claims AS (   -- 1) keep only independent claims
    SELECT 
        pcs."pat_no",
        pcs."claim_no",
        pcs."word_ct"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_CLAIMS_STATS pcs
    WHERE pcs."ind_flg" = '1'
), joined AS (                  -- 2) join to publication info
    SELECT
        ic."pat_no",
        ic."claim_no",
        ic."word_ct",
        pub."publication_number",
        pub."application_number",
        pub."publication_date",
        ROW_NUMBER() OVER (PARTITION BY pub."application_number"
                           ORDER BY pub."publication_date") AS rn  -- 3) earliest pub per application
    FROM independent_claims ic
    JOIN PATENTS_USPTO.USPTO_OCE_CLAIMS.MATCH m
         ON ic."pat_no" = m."pat_no"
    JOIN PATENTS_USPTO.PATENTS.PUBLICATIONS pub
         ON m."publication_number" = pub."publication_number"
)
SELECT
    "publication_number",
    "application_number",
    "claim_no",
    "word_ct"
FROM joined
WHERE rn = 1                       -- keep earliest publication in the family
ORDER BY "word_ct" DESC NULLS LAST -- 4) top 100 by word count (largest first)
LIMIT 100;