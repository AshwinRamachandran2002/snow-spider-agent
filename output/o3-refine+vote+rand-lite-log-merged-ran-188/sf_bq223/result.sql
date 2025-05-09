WITH
-- 1.  All DENSO-assigned publications having a valid filing date
"DENSO_PUBS" AS (
    SELECT DISTINCT
           p."publication_number"
    FROM   PATENTS.PATENTS.PUBLICATIONS p,
           LATERAL FLATTEN(input => p."assignee_harmonized") ah
    WHERE  ah.value:"name"::STRING ILIKE '%DENSO%'   -- any DENSO variant
      AND  p."filing_date" > 0                      -- valid filing date
),

-- 2.  All individual citation links where the cited patent is a DENSO patent
"CITATIONS_TO_DENSO" AS (
    SELECT
           citing."publication_number"                        AS "citing_pub_no",
           ah_citing.value:"name"::STRING                     AS "citing_assignee",
           cp.value:"code"::STRING                            AS "primary_cpc_code"
    FROM   PATENTS.PATENTS.PUBLICATIONS citing
    
           -- each cited reference
           , LATERAL FLATTEN(input => citing."citation") cit
    
           -- assignees of the citing patent
           , LATERAL FLATTEN(input => citing."assignee_harmonized") ah_citing
    
           -- CPC codes of the citing patent
           , LATERAL FLATTEN(input => citing."cpc") cp
    
    WHERE  cit.value:"publication_number"::STRING IN (SELECT "publication_number" FROM "DENSO_PUBS")
      AND  ah_citing.value:"name"::STRING NOT ILIKE '%DENSO%'        -- exclude DENSO as citer
      AND  cp.value:"first"::BOOLEAN = TRUE                           -- primary CPC only
),

-- 3.  Attach CPC subclass titles
"CITATIONS_WITH_TITLES" AS (
    SELECT
           ctd."citing_assignee",
           def."titleFull"                           AS "cpc_subclass_title"
    FROM   "CITATIONS_TO_DENSO"  ctd
           JOIN PATENTS.PATENTS.CPC_DEFINITION def
             ON def."symbol" = ctd."primary_cpc_code"
)

-- 4.  Aggregate counts
SELECT
       "citing_assignee",
       "cpc_subclass_title",
       COUNT(*) AS "citation_count"
FROM   "CITATIONS_WITH_TITLES"
GROUP  BY
       "citing_assignee",
       "cpc_subclass_title"
ORDER  BY
       "citation_count" DESC NULLS LAST;