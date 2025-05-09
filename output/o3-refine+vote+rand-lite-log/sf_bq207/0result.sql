WITH independent_claims AS (   -- all independent patent‑claim stats
    SELECT
        pcs."pat_no",
        pcs."appl_id",
        pcs."claim_no",
        TO_NUMBER(pcs."word_ct")               AS "word_ct"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS."PATENT_CLAIMS_STATS" pcs
    WHERE pcs."ind_flg" = '1'                             -- independent claims only
), matched_publications AS (    -- map patents to their publication numbers
    SELECT
        ic.*,
        m."publication_number"
    FROM independent_claims           ic
    JOIN PATENTS_USPTO.USPTO_OCE_CLAIMS."MATCH"  m
          ON ic."pat_no" = m."pat_no"
), claim_pubs AS (              -- pull application & date info for each publication
    SELECT
        mp."pat_no",
        mp."claim_no",
        mp."word_ct",
        pub."application_number",
        pub."publication_number"    AS "pub_num",
        pub."publication_date"
    FROM matched_publications mp
    JOIN PATENTS_USPTO.PATENTS."PUBLICATIONS"  pub
          ON mp."publication_number" = pub."publication_number"
    WHERE pub."application_number" IS NOT NULL           -- keep rows we can group on
), earliest_pub_per_app AS (    -- keep only the earliest publication per application
    SELECT
        cp.*,
        ROW_NUMBER() OVER (PARTITION BY cp."application_number"
                           ORDER BY cp."publication_date" ASC) AS rn
    FROM claim_pubs cp
)
SELECT
    "pub_num"            AS "publication_number",
    "application_number",
    "claim_no",
    "word_ct"
FROM earliest_pub_per_app
WHERE rn = 1                                      -- earliest publication of each application
ORDER BY "word_ct" DESC NULLS LAST, "publication_number"
LIMIT 100;