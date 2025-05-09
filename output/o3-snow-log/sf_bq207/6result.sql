WITH ind_claims AS (   -- independent claims with a word-count
    SELECT
        pcs."pat_no",
        pcs."appl_id",
        pcs."claim_no",
        CAST(pcs."word_ct" AS NUMBER) AS "word_ct"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_CLAIMS_STATS pcs
    WHERE pcs."ind_flg" = '1'
      AND pcs."word_ct" IS NOT NULL
),

claim_to_pub AS (      -- add publication number via MATCH table
    SELECT
        ic.*,
        m."publication_number"
    FROM ind_claims ic
    JOIN PATENTS_USPTO.USPTO_OCE_CLAIMS.MATCH m
      ON ic."pat_no" = m."pat_no"
),

pub_details AS (       -- bring in application # and publication date
    SELECT
        ctp."pat_no",
        ctp."appl_id",
        ctp."claim_no",
        ctp."word_ct",
        ctp."publication_number",
        p."application_number_formatted"        AS "application_number",
        p."publication_date"
    FROM claim_to_pub ctp
    JOIN PATENTS_USPTO.PATENTS.PUBLICATIONS p
      ON ctp."publication_number" = p."publication_number"
),

ranked AS (            -- keep only the earliest publication per application
    SELECT
        pd.*,
        ROW_NUMBER() OVER (PARTITION BY pd."application_number"
                           ORDER BY pd."publication_date" ASC) AS rn
    FROM pub_details pd
)

SELECT
    "publication_number",
    "application_number",
    "claim_no",
    "word_ct"
FROM ranked
WHERE rn = 1                       -- earliest pub for each application
ORDER BY "word_ct" DESC NULLS LAST  -- highest-word-count first
LIMIT 100;                         -- top 100 results