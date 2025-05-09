WITH earliest_pub_per_app AS (
    SELECT
        pub."publication_number",
        pub."application_number",
        ROW_NUMBER() OVER (
            PARTITION BY pub."application_number"
            ORDER BY pub."publication_date" ASC
        ) AS rn_pub
    FROM PATENTS_USPTO.PATENTS.PUBLICATIONS pub
),
indep_claims AS (
    SELECT
        m."publication_number",
        ep."application_number",
        pcs."claim_no"                    AS claim_num,
        CAST(pcs."word_ct" AS INT)        AS word_count
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_CLAIMS_STATS pcs
    JOIN PATENTS_USPTO.USPTO_OCE_CLAIMS.MATCH               m
      ON pcs."pat_no" = m."pat_no"
    JOIN earliest_pub_per_app ep
      ON ep."publication_number" = m."publication_number"
     AND ep.rn_pub = 1                         -- keep earliest pub per application
    WHERE pcs."ind_flg" = '1'
      AND pcs."word_ct" IS NOT NULL
)

SELECT
    "publication_number",
    "application_number",
    claim_num,
    word_count
FROM indep_claims
ORDER BY word_count DESC NULLS LAST,
         "publication_number",
         claim_num
LIMIT 100;