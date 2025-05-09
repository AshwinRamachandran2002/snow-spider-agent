/*  Top 100 longest independent-claim publications (earliest pub per application)  */
SELECT
    pub."publication_number"                              AS "publication_number",
    pub."application_number"                              AS "application_number",
    pcs."claim_no"                                         AS "claim_number",
    TRY_TO_NUMBER(pcs."word_ct")                           AS "word_count"
FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_CLAIMS_STATS      pcs
JOIN PATENTS_USPTO.USPTO_OCE_CLAIMS.MATCH                     m
      ON pcs."pat_no" = m."pat_no"
JOIN PATENTS_USPTO.PATENTS.PUBLICATIONS                       pub
      ON m."publication_number" = pub."publication_number"
WHERE pcs."ind_flg" = '1'          -- keep independent claims only
QUALIFY  pub."publication_date" = MIN(pub."publication_date")
                                      OVER (PARTITION BY pub."application_number")
ORDER BY TRY_TO_NUMBER(pcs."word_ct") DESC NULLS LAST
LIMIT 100;