/*  ------------------------------------------------------------
    Who cites DENSO patents?
    ------------------------------------------------------------
    1. denso_pubs          : all publication numbers whose assignee is DENSO CORP
    2. citing_pub_list     : every publication that cites one of those numbers
                             (keeps only records with a valid filing date)
    3. citing_patents      : enrich the citing publications with
                             • their (first) CPC code
                             • their assignee      –– excluding DENSO CORP itself
    ------------------------------------------------------------
*/
WITH denso_pubs AS (          -- DENSO‑owned publications
    SELECT DISTINCT p."publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN( INPUT => p."assignee_harmonized") ah
    WHERE UPPER(ah.value:"name"::string) = 'DENSO CORP'
),

citing_pub_list AS (          -- Publications that cite a DENSO publication
    SELECT DISTINCT
           cp."publication_number"      AS citing_pub
    FROM PATENTS.PATENTS.PUBLICATIONS  cp
         , LATERAL FLATTEN(INPUT => cp."citation") cit
         INNER JOIN denso_pubs dp
                 ON cit.value:"publication_number"::string = dp."publication_number"
    WHERE cp."filing_date" IS NOT NULL
      AND cp."filing_date" > 0
),

citing_patents AS (           -- Add primary CPC and citing assignee
    SELECT DISTINCT
           cp."publication_number"                AS citing_pub,
           ah.value:"name"::string               AS citing_assignee,
           cpc.value:"code"::string              AS primary_cpc_code
    FROM PATENTS.PATENTS.PUBLICATIONS  cp
         JOIN citing_pub_list l
               ON l.citing_pub = cp."publication_number"
         , LATERAL FLATTEN(INPUT => cp."assignee_harmonized") ah
         , LATERAL FLATTEN(INPUT => cp."cpc")                cpc
    WHERE cpc.value:"first"::boolean = TRUE
      AND UPPER(ah.value:"name"::string) <> 'DENSO CORP'   -- exclude self‑citations
)

SELECT
       cp.citing_assignee                                   AS "CITING_ASSIGNEE",
       COALESCE(cd."titleFull", 'UNKNOWN')                  AS "CPC_SUBCLASS_TITLE",
       COUNT(DISTINCT cp.citing_pub)                        AS "CITATION_COUNT"
FROM citing_patents cp
LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION cd
       ON cd."symbol" = cp.primary_cpc_code
GROUP BY cp.citing_assignee, cd."titleFull"
ORDER BY "CITATION_COUNT" DESC NULLS LAST,
         "CITING_ASSIGNEE";