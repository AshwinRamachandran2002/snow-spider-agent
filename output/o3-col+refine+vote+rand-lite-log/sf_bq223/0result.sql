/*  Assignees (excluding DENSO CORP) that cite DENSO-assigned patents,
    together with the titles of the primary CPC subclasses (based on the
    first/primary CPC code of each citing patent) and the number of such
    citations.                                                 */

WITH denso_pubs AS (  -- all publication numbers owned by DENSO CORP
    SELECT DISTINCT  p."publication_number"
    FROM   PATENTS.PATENTS.PUBLICATIONS  p,
           LATERAL FLATTEN (input => p."assignee_harmonized") ah
    WHERE  ah.value:"name"::STRING ILIKE '%DENSO%'
),

citing_set AS (       -- publications that cite a DENSO patent and have a filing date
    SELECT DISTINCT  cp."publication_number"
    FROM   PATENTS.PATENTS.PUBLICATIONS  cp,
           LATERAL FLATTEN (input => cp."citation") c
    WHERE  c.value:"publication_number"::STRING IN (SELECT "publication_number" FROM denso_pubs)
      AND  cp."filing_date" IS NOT NULL
),

citing_details AS (   -- first CPC code and assignee of each citing publication
    SELECT
        cs."publication_number"                                AS "citing_pub",
        ah2.value:"name"::STRING                               AS "citing_assignee",
        SPLIT_PART(cpc1.value:"code"::STRING, '/', 0)          AS "cpc_subclass"
    FROM   citing_set               cs
    JOIN   PATENTS.PATENTS.PUBLICATIONS pub
           ON pub."publication_number" = cs."publication_number",
           LATERAL FLATTEN (input => pub."assignee_harmonized")  ah2,
           LATERAL FLATTEN (input => pub."cpc")                  cpc1
    WHERE  cpc1.value:"first"::BOOLEAN = TRUE                   -- primary CPC only
      AND  ah2.value:"name"::STRING NOT ILIKE '%DENSO%'         -- exclude DENSO as citer
)

SELECT
    cd."citing_assignee",
    def."titleFull"                           AS "cpc_subclass_title",
    COUNT(*)                                  AS "citation_count"
FROM   citing_details cd
LEFT   JOIN PATENTS.PATENTS.CPC_DEFINITION def
       ON def."symbol" = cd."cpc_subclass"
GROUP  BY cd."citing_assignee", def."titleFull"
ORDER  BY "citation_count" DESC NULLS LAST;