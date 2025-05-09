/* -----------------------------------------------------------
   Citing assignees (excluding DENSO CORP) that have cited
   patents assigned to DENSO CORP, together with the full
   title of the CPC subclass (taken from the first CPC code
   of each citing patent) and the number of such citations.
----------------------------------------------------------- */

WITH denso_publications AS (          /* 1.  All DENSO‑assigned publications */
    SELECT DISTINCT
           P."publication_number"
    FROM   PATENTS.PATENTS.PUBLICATIONS  P,
           LATERAL FLATTEN(
               INPUT => P."assignee_harmonized"
           ) AS A
    WHERE  UPPER(A.VALUE:"name"::STRING) = 'DENSO CORP'
),

citing_edges AS (                     /* 2.  Citations *to* those publications */
    SELECT
           P."publication_number"                         AS "citing_pub",
           AH.VALUE:"name"::STRING                        AS "citing_assignee",
           CP.VALUE:"code"::STRING                        AS "cpc_code"
    FROM   PATENTS.PATENTS.PUBLICATIONS  P

           /* -- each backward citation ------------------ */
           ,LATERAL FLATTEN(
               INPUT => P."citation"
           )                      CIT

           /* -- citing patent’s assignees --------------- */
           ,LATERAL FLATTEN(
               INPUT => P."assignee_harmonized"
           )                      AH

           /* -- first (primary) CPC code ---------------- */
           ,LATERAL FLATTEN(
               INPUT => P."cpc"
           )                      CP

           /* -- publications assigned to DENSO ---------- */
           ,denso_publications      D

    WHERE  CIT.VALUE:"publication_number"::STRING = D."publication_number"     -- cites a DENSO patent
      AND  P."filing_date" > 0                                                -- valid filing date
      AND  CP.VALUE:"first"::BOOLEAN = TRUE                                   -- primary CPC code
      AND  UPPER(AH.VALUE:"name"::STRING) <> 'DENSO CORP'                     -- exclude DENSO as citer
)

SELECT
       CE."citing_assignee"                                            AS "CITING_ASSIGNEE",
       CD."titleFull"                                                  AS "CPC_SUBCLASS_TITLE",
       COUNT(*)                                                        AS "CITATION_COUNT"
FROM   citing_edges                CE
LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION  CD
       ON  CD."symbol" = SUBSTR(CE."cpc_code", 1, 4)   -- subclass = first 4 chars
GROUP BY
       CE."citing_assignee",
       CD."titleFull"
ORDER BY
       "CITATION_COUNT" DESC NULLS LAST,
       "CITING_ASSIGNEE";