WITH earliest AS (
    SELECT
        "application_number",
        MIN("publication_date")                                   AS first_pub_date,
        MIN_BY("publication_number","publication_date")           AS first_publication_number
    FROM PATENTS_USPTO.PATENTS.PUBLICATIONS
    GROUP BY "application_number"
)

SELECT
    e."application_number",
    e.first_publication_number            AS "publication_number",
    pcs."claim_no",
    pcs."word_ct"
FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_CLAIMS_STATS  pcs
JOIN PATENTS_USPTO.USPTO_OCE_CLAIMS.MATCH                 m
      ON pcs."pat_no" = m."pat_no"
JOIN earliest                                             e
      ON REGEXP_REPLACE(m."publication_number", '[^0-9]', '') =
         REGEXP_REPLACE(e.first_publication_number, '[^0-9]', '')
WHERE pcs."ind_flg" = '1'
ORDER BY TO_NUMBER(pcs."word_ct") DESC NULLS LAST
LIMIT 100;