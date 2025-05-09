/*  Assignees (excluding DENSO CORP) that have cited patents assigned to DENSO CORP,
    together with the title of the primary CPC subclass of the citing patents
    and the number of such citation events                                            */

WITH denso_pubs AS (          -- 1.  All publications whose assignee includes “DENSO CORP”
    SELECT DISTINCT
        "publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "assignee_harmonized"::STRING ILIKE '%DENSO CORP%'
),

citing_events AS (            -- 2.  Each individual citation **to** a DENSO patent
    SELECT DISTINCT           --     (distinct to avoid double‑counting identical rows)
        p."publication_number"                 AS "citing_pub",
        cit.value:"publication_number"::STRING AS "cited_denso_pub",
        ass.value:"name"::STRING               AS "citing_assignee",
        cpc.value:"code"::STRING               AS "cpc_symbol"
    FROM PATENTS.PATENTS.PUBLICATIONS p
         , LATERAL FLATTEN(input => p."citation")            cit
         , LATERAL FLATTEN(input => p."assignee_harmonized") ass
         , LATERAL FLATTEN(input => p."cpc")                 cpc
    WHERE cit.value:"publication_number"::STRING IN (SELECT "publication_number" FROM denso_pubs)   -- cites DENSO
      AND p."filing_date" IS NOT NULL                                                            -- valid filing date
      AND ass.value:"name"::STRING NOT ILIKE '%DENSO CORP%'                                      -- exclude DENSO as citer
      AND cpc.value:"first"::BOOLEAN = TRUE                                                      -- primary CPC only
)

SELECT
    cd."titleFull"               AS "cpc_subclass_title",
    ce."citing_assignee",
    COUNT(*)                     AS "citation_count"
FROM citing_events  ce
LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION cd
       ON cd."symbol" = ce."cpc_symbol"
GROUP BY
    ce."citing_assignee",
    cd."titleFull"
ORDER BY
    "citation_count" DESC NULLS LAST,
    "citing_assignee";