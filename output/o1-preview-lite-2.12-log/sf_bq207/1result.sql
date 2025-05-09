SELECT p."publication_number", p."application_number", pcs."claim_no", pcs."word_ct"
FROM "PATENTS_USPTO"."USPTO_OCE_CLAIMS"."PATENT_CLAIMS_STATS" pcs
JOIN "PATENTS_USPTO"."USPTO_OCE_CLAIMS"."MATCH" m
  ON pcs."pat_no" = m."pat_no"
JOIN (
    SELECT p.*, ROW_NUMBER() OVER (PARTITION BY p."application_number" ORDER BY p."publication_date" ASC) AS "rn"
    FROM "PATENTS_USPTO"."PATENTS"."PUBLICATIONS" p
) p
  ON m."publication_number" = p."publication_number" AND p."rn" = 1
WHERE pcs."ind_flg" = '1'
ORDER BY pcs."word_ct" DESC NULLS LAST
LIMIT 100;