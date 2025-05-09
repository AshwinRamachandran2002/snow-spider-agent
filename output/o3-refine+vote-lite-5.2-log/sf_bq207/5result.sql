/*  Top‑100 longest independent patent claims,
    returning the earliest publication for each application            */

WITH independent_claims AS (   -- all independent (ind_flg = '1') patent‑level claims
    SELECT
        CAST("word_ct" AS INTEGER) AS word_ct_int ,   -- convert to number for ordering
        "pat_no",
        "appl_id",
        "claim_no"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_CLAIMS_STATS
    WHERE "ind_flg" = '1'
),
claims_with_pubs AS (          -- connect each patent claim to its publication number
    SELECT
        ic.word_ct_int            AS word_ct,
        ic."claim_no",
        ic."pat_no",
        m."publication_number"
    FROM independent_claims ic
    JOIN PATENTS_USPTO.USPTO_OCE_CLAIMS.MATCH m
          ON m."pat_no" = ic."pat_no"
),
pubs_with_app AS (             -- add application & publication dates, mark earliest pub per application
    SELECT
        cwp.word_ct,
        cwp."claim_no",
        cwp."publication_number",
        p."application_number",
        p."publication_date",
        ROW_NUMBER() OVER (PARTITION BY p."application_number"
                           ORDER BY p."publication_date" ASC) AS rn
    FROM claims_with_pubs  cwp
    JOIN PATENTS_USPTO.PATENTS.PUBLICATIONS p
          ON p."publication_number" = cwp."publication_number"
)
SELECT
    "publication_number",
    "application_number",
    "claim_no",
    word_ct                               -- already numeric
FROM pubs_with_app
WHERE rn = 1                              -- keep only earliest publication per application
ORDER BY word_ct DESC NULLS LAST          -- highest‑word‑count first
LIMIT 100;