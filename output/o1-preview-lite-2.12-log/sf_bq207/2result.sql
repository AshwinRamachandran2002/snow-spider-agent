SELECT
  t."publication_number",
  t."application_number",
  t."claim_no",
  t."word_ct"
FROM (
  SELECT
    p."publication_number",
    p."application_number",
    pcs."claim_no",
    pcs."word_ct",
    ROW_NUMBER() OVER (
      PARTITION BY p."application_number"
      ORDER BY p."filing_date" ASC, pcs."word_ct" DESC
    ) AS rn
  FROM
    "PATENTS_USPTO"."USPTO_OCE_CLAIMS"."PATENT_CLAIMS_STATS" pcs
  JOIN
    "PATENTS_USPTO"."USPTO_OCE_CLAIMS"."MATCH" m ON pcs."pat_no" = m."pat_no"
  JOIN
    "PATENTS_USPTO"."PATENTS"."PUBLICATIONS" p ON m."publication_number" = p."publication_number"
  WHERE
    pcs."ind_flg" = '1' AND p."filing_date" IS NOT NULL
) t
WHERE
  t.rn = 1
ORDER BY
  t."word_ct" DESC NULLS LAST
LIMIT 100;