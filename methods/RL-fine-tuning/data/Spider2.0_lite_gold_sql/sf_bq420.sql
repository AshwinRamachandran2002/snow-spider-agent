SELECT
    pd."pat_no" AS "PatentNumber",
    MIN(pf."publication_number") AS "FirstPublicationNumber",
    MIN(pf."publication_date") AS "FirstPublicationDate",
    MAX(TRY_TO_NUMBER(pgd."pub_wrd_ct")) AS "LengthOfFiledClaims",
    TRY_TO_NUMBER(pd."pat_wrd_ct") AS "LengthOfGrantedClaims",
    p."grant_date" AS "GrantDate",
    p."filing_date" AS "FirstOfficeActionDate"
FROM
    "PATENTS_USPTO"."USPTO_OCE_CLAIMS"."PATENT_DOCUMENT_STATS" pd
JOIN
    "PATENTS_USPTO"."PATENTS"."PUBLICATIONS" p
    ON pd."pat_no" = REGEXP_REPLACE(p."publication_number", '^US-|-[A-Za-z0-9]+$', '')
LEFT JOIN
    "PATENTS_USPTO"."PATENTS"."PUBLICATIONS" pf
    ON p."application_number" = pf."application_number"
    AND TRY_TO_NUMBER(pf."publication_date") IS NOT NULL
LEFT JOIN
    "PATENTS_USPTO"."USPTO_OCE_CLAIMS"."PGPUB_DOCUMENT_STATS" pgd
    ON pd."appl_id" = pgd."appl_id"
WHERE
    TRY_TO_NUMBER(p."grant_date") >= 20100101
    AND TRY_TO_NUMBER(p."grant_date") <= 20231231
GROUP BY
    pd."pat_no",
    pd."pat_wrd_ct",
    p."grant_date",
    p."filing_date"
ORDER BY
    TRY_TO_NUMBER(pd."pat_wrd_ct") DESC NULLS LAST
LIMIT 5;