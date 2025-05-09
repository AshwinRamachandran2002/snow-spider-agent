WITH denso_publications AS (     -- All publications that are assigned to DENSO CORP
    SELECT DISTINCT
           "publication_number"
    FROM   PATENTS.PATENTS.PUBLICATIONS,
           LATERAL FLATTEN(input => "assignee_harmonized") AS a
    WHERE  UPPER(TRIM(a.value:name::string)) = 'DENSO CORP'
),
citing_relations AS (            -- Every citation that points to a DENSO CORP patent
    SELECT
           assignee.value:name::string                            AS citing_assignee,
           cpc_first.value:code::string                           AS cpc_code
    FROM   PATENTS.PATENTS.PUBLICATIONS               p
           , LATERAL FLATTEN(input => p."citation")              AS cited
           , LATERAL FLATTEN(input => p."assignee_harmonized")   AS assignee
           , LATERAL FLATTEN(input => p."cpc")                   AS cpc_first
    WHERE  cited.value:publication_number::string IN (SELECT "publication_number" FROM denso_publications)
      AND  p."filing_date" IS NOT NULL
      AND  p."filing_date" > 0                       -- keep only valid filing dates
      AND  cpc_first.value:first::boolean = TRUE     -- take the primary CPC only
      AND  UPPER(TRIM(assignee.value:name::string)) <> 'DENSO CORP'  -- exclude self‑citations
)
SELECT
       cr.citing_assignee                                              AS "CITING_ASSIGNEE",
       cd."titleFull"                                                  AS "CPC_SUBCLASS_TITLE",
       COUNT(*)                                                        AS "CITATION_COUNT"
FROM   citing_relations          cr
       JOIN PATENTS.PATENTS.CPC_DEFINITION cd
         ON cd."symbol" = cr.cpc_code
GROUP  BY cr.citing_assignee,
          cd."titleFull"
ORDER  BY "CITATION_COUNT" DESC NULLS LAST,
          "CITING_ASSIGNEE";