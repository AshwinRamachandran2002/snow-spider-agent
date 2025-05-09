SELECT
    base."publication_number",
    base."application_number",
    base."claim_no"        AS "claim_number",
    base."word_ct"::NUMBER AS "word_count"
FROM (
    SELECT
        pub."publication_number",
        pub."application_number",
        pcs."claim_no",
        pcs."word_ct",
        ROW_NUMBER() OVER (
            PARTITION BY pub."application_number"
            ORDER BY     pub."publication_date" ASC,
                         pub."publication_number" ASC
        ) AS rn
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_CLAIMS_STATS       AS pcs
    JOIN PATENTS_USPTO.USPTO_OCE_CLAIMS.MATCH                     AS m
          ON pcs."pat_no" = m."pat_no"
    JOIN PATENTS_USPTO.PATENTS.PUBLICATIONS                       AS pub
          ON pub."publication_number" = m."publication_number"
    WHERE pcs."ind_flg" = '1'
      AND pcs."word_ct" IS NOT NULL
) AS base
WHERE base.rn = 1                           -- keep earliest publication per application
ORDER BY base."word_ct"::NUMBER DESC NULLS LAST,
         base."publication_number"
LIMIT 100;