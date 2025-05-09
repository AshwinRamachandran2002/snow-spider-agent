/* -----------------------------------------------------------
   Citing–cited network:
   –  Patents ASSIGNED to “DENSO CORP”  (cited patents)
   –  Patents that CITE one of those DENSO patents (citing patents)
   For every citing‑patent we keep
        • every non‑DENSO citing‑assignee (assignee_harmonized list)
        • the first CPC code that appears in its CPC array
   We then count the number of individual citation links
   grouped by (citing‑assignee × CPC‑subclass‑title).
------------------------------------------------------------*/
WITH denso_publications AS (          /* all publications whose assignee = DENSO CORP    */
    SELECT DISTINCT
           UPPER("publication_number")     AS "publication_number"
    FROM   PATENTS.PATENTS.PUBLICATIONS p,
           LATERAL FLATTEN(input => p."assignee_harmonized") ah
    WHERE  UPPER(ah.value:"name"::STRING) = 'DENSO CORP'
),

/* -----------------------------------------------------------------
   All citation links where the cited publication is a DENSO patent.
   Keep only citing patents with a non‑null filing_date.
------------------------------------------------------------------*/
citation_links AS (
    SELECT
           UPPER(p."publication_number")           AS "citing_pub",
           cl.value:"publication_number"::STRING   AS "cited_pub",
           p."assignee_harmonized"                 AS "citing_assignees",
           p."cpc"                                 AS "citing_cpc"
    FROM   PATENTS.PATENTS.PUBLICATIONS p,
           LATERAL FLATTEN(input => p."citation")  cl
    WHERE  p."filing_date" IS NOT NULL                       -- valid filing date
      AND  UPPER(cl.value:"publication_number"::STRING) IN (
                 SELECT "publication_number" FROM denso_publications
           )
),

/* -----------------------------------------------------------------
   For every citing publication:
      – explode the list of harmonized assignees
      – explode the CPC array
   Keep     • assignees ≠ DENSO CORP
            • only the FIRST CPC entry (smallest array index)
------------------------------------------------------------------*/
citing_assignee_cpc AS (
    SELECT
        ca.value:"name"::STRING                      AS "citing_assignee",
        cp.value:"code"::STRING                      AS "cpc_code",
        citation_links."citing_pub",
        ROW_NUMBER() OVER (PARTITION BY citation_links."citing_pub"
                           ORDER BY cp.index)        AS rn_cpc
    FROM   citation_links,
           LATERAL FLATTEN(input => citation_links."citing_assignees") ca,
           LATERAL FLATTEN(input => citation_links."citing_cpc")      cp
    WHERE  UPPER(ca.value:"name"::STRING) <> 'DENSO CORP'             -- exclude DENSO as citer
),

primary_cpc_per_citing_pub AS (       -- keep only the first CPC code per citing patent
    SELECT   "citing_pub",
             "citing_assignee",
             "cpc_code"
    FROM     citing_assignee_cpc
    WHERE    rn_cpc = 1
),

/* -----------------------------------------------------------------
   Join to CPC_DEFINITION for the full subclass title.
------------------------------------------------------------------*/
with_titles AS (
    SELECT
        pc."citing_assignee",
        cd."titleFull"                           AS "cpc_title",
        pc."citing_pub"
    FROM   primary_cpc_per_citing_pub pc
    LEFT  JOIN PATENTS.PATENTS.CPC_DEFINITION cd
           ON cd."symbol" = pc."cpc_code"
)

/* -----------------------------------------------------------------
   Final aggregation: count individual citation links
   (a link = one citing publication that cites at least one DENSO patent)
------------------------------------------------------------------*/
SELECT
       "citing_assignee"                                    AS "CITING_ASSIGNEE",
       COALESCE("cpc_title", '[TITLE NOT FOUND]')           AS "CPC_SUBCLASS_TITLE",
       COUNT(DISTINCT "citing_pub")                         AS "CITATION_COUNT"
FROM   with_titles
GROUP  BY "citing_assignee", "cpc_title"
ORDER  BY "CITATION_COUNT" DESC NULLS LAST,
          "citing_assignee";