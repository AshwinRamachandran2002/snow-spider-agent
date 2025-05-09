/*  Citing-assignee × CPC-subclass title counts for citations to DENSO patents  */

WITH "densopubs" AS (   -- all publications assigned to DENSO (any variant of the name)
    SELECT DISTINCT p."publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."assignee_harmonized") ah
    WHERE ah.value:"name"::STRING ILIKE '%DENSO%'
),
"citingpubs" AS (       -- publications that cite one of the DENSO publications
    SELECT DISTINCT p2."publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS p2,
         LATERAL FLATTEN(input => p2."citation") cit
    WHERE cit.value:"publication_number"::STRING IN (SELECT "publication_number" FROM "densopubs")
      AND p2."filing_date" IS NOT NULL              -- keep only records with a valid filing date
)
SELECT
    ass.value:"name"::STRING              AS "citing_assignee",
    cd."titleFull"                        AS "primary_cpc_title",
    COUNT(*)                              AS "citation_count"
FROM PATENTS.PATENTS.PUBLICATIONS pub
     JOIN "citingpubs" cp
       ON pub."publication_number" = cp."publication_number"
     ,LATERAL FLATTEN(input => pub."assignee_harmonized") ass
     ,LATERAL FLATTEN(input => pub."cpc") cpc
     JOIN PATENTS.PATENTS.CPC_DEFINITION cd
       ON cd."symbol" = SUBSTR(cpc.value:"code"::STRING, 1, 4)   -- 4-digit CPC symbol
WHERE cpc.value:"first"::BOOLEAN = TRUE            -- use only the primary CPC code(s)
  AND ass.value:"name"::STRING NOT ILIKE '%DENSO%' -- exclude DENSO as a citing assignee
GROUP BY
    ass.value:"name"::STRING,
    cd."titleFull"
ORDER BY
    "citation_count" DESC NULLS LAST;