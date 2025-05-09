WITH ind_claims AS (          -- independent‑claim word counts + publication #
    SELECT
        PCS."pat_no",
        M."publication_number",
        PCS."claim_no",
        TRY_TO_NUMBER(PCS."word_ct") AS word_cnt
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_CLAIMS_STATS  PCS
    JOIN PATENTS_USPTO.USPTO_OCE_CLAIMS.MATCH               M
          ON PCS."pat_no" = M."pat_no"
    WHERE PCS."ind_flg" = '1'
),
earliest_pub AS (             -- keep only the first publication per application
    SELECT
        P."publication_number",
        P."application_number",
        ROW_NUMBER() OVER (
            PARTITION BY P."application_number"
            ORDER BY P."publication_date" ASC
        ) AS rn
    FROM PATENTS_USPTO.PATENTS.PUBLICATIONS P
)
SELECT
    ic."publication_number",
    ep."application_number",
    ic."claim_no",
    ic.word_cnt
FROM ind_claims   ic
JOIN earliest_pub ep
      ON ic."publication_number" = ep."publication_number"
WHERE ep.rn = 1                -- earliest publication for each application
ORDER BY ic.word_cnt DESC NULLS LAST,  -- largest claims first
         ep."application_number"
LIMIT 100;