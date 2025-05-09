/*  -----------------------------------------------------------
    Which assignees (excluding DENSO CORP) cite patents that are
    assigned to DENSO CORP and what CPC‑subclass titles are
    involved?  Count citations by assignee × CPC‑title.
    ----------------------------------------------------------- */
WITH "DENSO_PUBS" AS (   -- DENSO‑assigned publications with valid filing dates
    SELECT DISTINCT p."publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(INPUT => p."assignee_harmonized") ah
    WHERE UPPER(ah.VALUE:"name"::string) = 'DENSO CORP'
      AND p."filing_date" IS NOT NULL
      AND p."filing_date" > 0
),

/* 1) Identify publications that cite any of the DENSO patents.
      We only FLATTEN the citation array here to keep the dataset
      small, postponing other FLATTEN operations for later steps. */
"CITING_PUBS" AS (
    SELECT DISTINCT cp."publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS cp,
         LATERAL FLATTEN(INPUT => cp."citation") cit
    WHERE cit.VALUE:"publication_number"::string IN (SELECT "publication_number" FROM "DENSO_PUBS")
),

/* 2) For the citing publications found above, extract the
      (i) citing‑assignee,
      (ii) first CPC code (index 0)                     */
"CITING_DATA" AS (
    SELECT
        cp."publication_number"                      AS "citing_pub",
        ass.VALUE:"name"::string                     AS "citing_assignee",
        cpc.VALUE:"code"::string                     AS "primary_cpc"
    FROM PATENTS.PATENTS.PUBLICATIONS cp
    JOIN "CITING_PUBS" cp_set
      ON cp."publication_number" = cp_set."publication_number"
    ,    LATERAL FLATTEN(INPUT => cp."assignee_harmonized") ass
    ,    LATERAL FLATTEN(INPUT => cp."cpc")          cpc
    WHERE cpc.index = 0                    -- first CPC only
      AND UPPER(ass.VALUE:"name"::string) <> 'DENSO CORP'
      AND cp."filing_date" IS NOT NULL
      AND cp."filing_date" > 0
)

SELECT
    cdta."citing_assignee"                AS "CITING_ASSIGNEE",
    cpc_def."titleFull"                   AS "CPC_SUBCLASS_TITLE",
    COUNT(*)                              AS "CITATION_COUNT"
FROM "CITING_DATA" cdta
JOIN PATENTS.PATENTS.CPC_DEFINITION cpc_def
      ON cpc_def."symbol" = cdta."primary_cpc"
GROUP BY cdta."citing_assignee",
         cpc_def."titleFull"
ORDER BY "CITATION_COUNT" DESC NULLS LAST,
         "CITING_ASSIGNEE",
         "CPC_SUBCLASS_TITLE";