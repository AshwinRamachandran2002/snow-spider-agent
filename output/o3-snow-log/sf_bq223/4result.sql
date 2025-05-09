/* ---  Assignees (except DENSO CORP) that cite any patent owned by DENSO CORP,
        together with the full title of the primary CPC subclass of the citing
        publication and the number of such citing publications.  --- */

WITH denso_pubs AS (   -- all publications that list DENSO CORP as (one) assignee
    SELECT DISTINCT p."publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(INPUT => p."assignee_harmonized") a
    WHERE UPPER(a.value:"name"::STRING) LIKE '%DENSO%CORP%'
),

citing_pubs AS (       -- publications that cite at least one DENSO publication
    SELECT DISTINCT t."publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS t,
         LATERAL FLATTEN(INPUT => t."citation") c
    WHERE c.value:"publication_number"::STRING IN (SELECT "publication_number" FROM denso_pubs)
),

citing_details AS (    -- assignee name and primary CPC code of each citing pub
    SELECT
        t."publication_number",
        ass.value:"name"::STRING   AS "citing_assignee",
        cpc.value:"code"::STRING   AS "primary_cpc_code"
    FROM PATENTS.PATENTS.PUBLICATIONS t
    JOIN citing_pubs cp
      ON t."publication_number" = cp."publication_number",
         LATERAL FLATTEN(INPUT => t."assignee_harmonized") ass,
         LATERAL FLATTEN(INPUT => t."cpc") cpc
    WHERE cpc.index = 0                 -- first / primary CPC element
      AND t."filing_date" > 0           -- only records with valid filing dates
      AND UPPER(ass.value:"name"::STRING) NOT LIKE '%DENSO%CORP%'   -- exclude DENSO as citer
)

SELECT
    cdets."citing_assignee"                               AS "citing_assignee",
    cd."titleFull"                                        AS "cpc_subclass_title",
    COUNT(DISTINCT cdets."publication_number")            AS "citation_count"
FROM citing_details cdets
JOIN PATENTS.PATENTS.CPC_DEFINITION cd
  ON cd."symbol" = cdets."primary_cpc_code"
GROUP BY
    cdets."citing_assignee",
    cd."titleFull"
ORDER BY
    "citation_count" DESC NULLS LAST;