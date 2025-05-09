SELECT t."publication_number", t."application_number", t."claim_no", t."word_ct"
FROM (
    SELECT pcs."claim_no",
           CAST(pcs."word_ct" AS INTEGER) AS "word_ct",
           m."publication_number",
           p."application_number",
           p."publication_date",
           ROW_NUMBER() OVER (
               PARTITION BY p."application_number"
               ORDER BY p."publication_date" ASC
           ) AS "rn"
    FROM PATENTS_USPTO.USPTO_OCE_CLAIMS.PATENT_CLAIMS_STATS pcs
    INNER JOIN PATENTS_USPTO.USPTO_OCE_CLAIMS.MATCH m
        ON pcs."pat_no" = m."pat_no"
    INNER JOIN PATENTS_USPTO.PATENTS.PUBLICATIONS p
        ON m."publication_number" = p."publication_number"
    WHERE pcs."ind_flg" = '1'
) t
WHERE t."rn" = 1
ORDER BY t."word_ct" DESC NULLS LAST
LIMIT 100;