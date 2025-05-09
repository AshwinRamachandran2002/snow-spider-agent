/*  Assignees (other than DENSO CORP) that cite patents assigned to DENSO CORP,
    together with the title of the primary CPC subclass (first CPC code)
    and the number of such citations                                           */

WITH

/* ---- citing publications ------------------------------------------------- */
citing AS (
    SELECT
        cp."publication_number"                               AS citing_pub_number,
        ca.value:"name"::STRING                               AS citing_assignee,
        fc.value:"code"::STRING                               AS first_cpc_code,
        cit.value:"publication_number"::STRING                AS cited_pub_number
    FROM PATENTS.PATENTS.PUBLICATIONS  cp
         , LATERAL FLATTEN (INPUT => cp."citation")           cit          -- cited items
         , LATERAL FLATTEN (INPUT => cp."assignee_harmonized") ca           -- citing assignees
         , LATERAL FLATTEN (INPUT => cp."cpc")                fc           -- CPC codes
    WHERE cp."filing_date" > 0                                -- keep valid filing dates
      AND fc.value:"first"::BOOLEAN = TRUE                    -- primary CPC only
),

/* ---- publications whose assignee is DENSO CORP --------------------------- */
cited_denso AS (
    SELECT DISTINCT
           p."publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS p
         , LATERAL FLATTEN (INPUT => p."assignee_harmonized") a
    WHERE p."filing_date" > 0
      AND a.value:"name"::STRING ILIKE '%DENSO CORP%'         -- DENSO-assigned patents
)

/* ---- final aggregation --------------------------------------------------- */
SELECT
       c.citing_assignee                                      AS "CITING_ASSIGNEE",
       cd."titleFull"                                         AS "CPC_SUBCLASS_TITLE",
       COUNT(*)                                               AS "CITATION_COUNT"
FROM        citing            c
INNER JOIN  cited_denso       d   ON c.cited_pub_number = d."publication_number"
LEFT  JOIN  PATENTS.PATENTS.CPC_DEFINITION cd
           ON cd."symbol" = c.first_cpc_code                  -- title of primary CPC subclass
WHERE c.citing_assignee NOT ILIKE '%DENSO CORP%'              -- exclude self-citations
GROUP BY c.citing_assignee, cd."titleFull"
ORDER BY "CITATION_COUNT" DESC NULLS LAST;