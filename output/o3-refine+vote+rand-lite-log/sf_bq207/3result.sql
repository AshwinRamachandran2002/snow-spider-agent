WITH independent_claims AS (
    /* 1.  Independent‑claim statistics (ind_flg = '1') */
    SELECT
        pcs."pat_no",
        pcs."appl_id",
        pcs."claim_no",
        TRY_TO_NUMBER(pcs."word_ct")          AS "word_ct"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_CLAIMS_STATS pcs
    WHERE pcs."ind_flg" = '1'
),
claims_with_pubs AS (
    /* 2.  Map granted‑patent numbers to publication numbers */
    SELECT
        ic.*,
        m."publication_number"
    FROM independent_claims ic
    JOIN PATENTS_USPTO.USPTO_OCE_CLAIMS.MATCH m
          ON ic."pat_no" = m."pat_no"
),
ranked_pubs AS (
    /* 3.  Attach publication metadata and keep the earliest pub per application */
    SELECT
        cwp."pat_no",
        cwp."claim_no",
        cwp."word_ct",
        p."publication_number",
        p."application_number",
        p."publication_date",
        ROW_NUMBER() OVER (PARTITION BY p."application_number"
                           ORDER BY p."publication_date" ASC) AS rn
    FROM claims_with_pubs  cwp
    JOIN PATENTS_USPTO.PATENTS.PUBLICATIONS p
          ON cwp."publication_number" = p."publication_number"
    WHERE p."application_number" IS NOT NULL
)
SELECT
    "publication_number",
    "application_number",
    "claim_no",
    "word_ct"
FROM ranked_pubs
WHERE rn = 1
ORDER BY "word_ct" DESC NULLS LAST, "publication_number" ASC
LIMIT 100;