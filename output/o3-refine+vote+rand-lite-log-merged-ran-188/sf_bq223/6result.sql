/*  Which assignees (except DENSO CORP) have cited patents assigned to DENSO CORP,
    and what are the titles of the primary CPC subclasses (based on the “first” CPC
    code) of those citing patents?                                            */

WITH denso_pubs AS (           -- 1) All publications whose assignee is DENSO
    SELECT DISTINCT
           p."publication_number"
    FROM   PATENTS.PATENTS.PUBLICATIONS      p,
           LATERAL FLATTEN (INPUT => p."assignee_harmonized") ah
    WHERE  UPPER(ah.value:"name"::STRING) LIKE '%DENSO%'        -- covers “DENSO CORP”, “NIPPON DENSO”, etc.
),

citing_pub_numbers AS (        -- 2) Publications that cite any DENSO publication
    SELECT DISTINCT
           cp."publication_number"
    FROM   PATENTS.PATENTS.PUBLICATIONS      cp,
           LATERAL FLATTEN (INPUT => cp."citation") ct
           JOIN denso_pubs dp
             ON ct.value:"publication_number"::STRING = dp."publication_number"
    WHERE  cp."filing_date" > 0                                   -- keep only valid filing dates
),

citing_details AS (            -- 3) Extract citing-assignee and primary CPC subclass
    SELECT
           pub."publication_number",
           ass.value:"name"::STRING                 AS "citing_assignee",
           SUBSTR(cpc.value:"code"::STRING, 0, 4)   AS "cpc_subclass"
    FROM   citing_pub_numbers cpn
           JOIN PATENTS.PATENTS.PUBLICATIONS pub
             ON pub."publication_number" = cpn."publication_number",
           LATERAL FLATTEN (INPUT => pub."assignee_harmonized") ass,
           LATERAL FLATTEN (INPUT => pub."cpc")                cpc
    WHERE  cpc.value:"first"::BOOLEAN = TRUE                    -- primary CPC only
      AND  ass.value:"name"::STRING NOT ILIKE '%denso%'         -- exclude DENSO as citer
)

SELECT
       cd."titleFull"                      AS "cpc_subclass_title",
       cd."symbol"                         AS "cpc_subclass",
       cdets."citing_assignee",
       COUNT(*)                            AS "n_citations"
FROM   citing_details              cdets
       LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION cd
              ON cd."symbol" = cdets."cpc_subclass"
GROUP BY
       cdets."citing_assignee",
       cd."titleFull",
       cd."symbol"
ORDER BY
       "n_citations" DESC NULLS LAST;