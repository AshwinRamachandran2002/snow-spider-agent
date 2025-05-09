WITH earliest_pub AS (   -- earliest publication per application
    SELECT
        "publication_number",
        "application_number"
    FROM (
        SELECT
            p."publication_number",
            p."application_number",
            p."publication_date",
            ROW_NUMBER() OVER (PARTITION BY p."application_number"
                               ORDER BY p."publication_date" ASC,
                                        p."publication_number" ASC) AS rn
        FROM PATENTS_USPTO.PATENTS.PUBLICATIONS p
        WHERE p."application_number" IS NOT NULL
          AND p."publication_number" IS NOT NULL
    )
    WHERE rn = 1
),
independent_claims AS (  -- independent claims with word counts
    SELECT
        pcs."pat_no",
        pcs."claim_no",
        TRY_CAST(pcs."word_ct" AS INTEGER) AS word_ct
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_CLAIMS_STATS pcs
    WHERE pcs."ind_flg" = '1'
      AND pcs."word_ct" IS NOT NULL
),
claims_with_pub AS (     -- link claims to their publication numbers
    SELECT
        ic."pat_no",
        ic."claim_no",
        ic.word_ct,
        m."publication_number"
    FROM independent_claims ic
    JOIN PATENTS_USPTO.USPTO_OCE_CLAIMS.MATCH m
      ON ic."pat_no" = m."pat_no"
)
SELECT
    ep."publication_number",
    ep."application_number",
    cwp."claim_no",
    cwp.word_ct
FROM claims_with_pub  cwp
JOIN earliest_pub     ep
  ON cwp."publication_number" = ep."publication_number"
ORDER BY
    cwp.word_ct DESC NULLS LAST,
    ep."publication_number",
    cwp."claim_no"
LIMIT 100;