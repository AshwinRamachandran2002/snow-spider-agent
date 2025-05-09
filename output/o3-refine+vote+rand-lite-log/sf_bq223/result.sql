/*  Assignees (excluding DENSO CORP) that cite patents assigned to DENSO CORP,
    together with the title of the primary CPC subclass (first CPC code)
    and the number of such citations.                                           */

WITH denso_pubs AS (  -- 1. Publications whose assignee is DENSO CORP
    SELECT DISTINCT p."publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."assignee_harmonized") a
    WHERE UPPER(a.value:"name"::STRING) LIKE 'DENSO CORP%'
),

citations_to_denso AS (  -- 2. Publications that cite any DENSO publication
    SELECT
        cp."publication_number"  AS citing_pub,
        cp."assignee_harmonized" AS citing_assignees,
        cp."cpc"                 AS citing_cpc
    FROM PATENTS.PATENTS.PUBLICATIONS cp,
         LATERAL FLATTEN(input => cp."citation") cit
    WHERE cit.value:"publication_number"::STRING IN (SELECT "publication_number" FROM denso_pubs)
      AND cp."filing_date" IS NOT NULL
),

expanded AS (  -- 3. Expand assignees & keep the first CPC code only
    SELECT
        ass.value:"name"::STRING      AS citing_assignee,
        cpc_elem.value:"code"::STRING AS primary_cpc_code
    FROM citations_to_denso ctd,
         LATERAL FLATTEN(input => ctd.citing_assignees) ass,
         LATERAL FLATTEN(input => ctd.citing_cpc)      cpc_elem
    WHERE cpc_elem."INDEX" = 0                                        -- first CPC entry
      AND UPPER(ass.value:"name"::STRING) NOT LIKE 'DENSO CORP%'      -- exclude DENSO
),

cpc_titles AS (  -- 4. CPC code ↔ full title
    SELECT
        "symbol"    AS cpc_code,
        "titleFull" AS cpc_title
    FROM PATENTS.PATENTS.CPC_DEFINITION
)

-- 5. Final aggregation
SELECT
    e.citing_assignee                 AS "CITING_ASSIGNEE",
    COALESCE(ct.cpc_title, 'UNKNOWN') AS "CPC_SUBCLASS_TITLE",
    COUNT(*)                          AS "CITATION_COUNT"
FROM expanded e
LEFT JOIN cpc_titles ct
       ON ct.cpc_code = e.primary_cpc_code
GROUP BY
    e.citing_assignee,
    ct.cpc_title
ORDER BY
    "CITATION_COUNT" DESC NULLS LAST,
    "CITING_ASSIGNEE",
    "CPC_SUBCLASS_TITLE";