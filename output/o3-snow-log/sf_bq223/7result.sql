/* 1) collect all DENSO CORP-assigned publications that have a valid filing date            */
/* 2) look for patents that cite any of those publications                                  */
/* 3) keep only the non-DENSO citing assignees                                              */
/* 4) keep the “first” CPC code for each citing patent                                      */
/* 5) aggregate citations by (citing-assignee , CPC title)                                  */

WITH denso_pubs AS (       -- step-1
    SELECT DISTINCT
           "publication_number"
    FROM   PATENTS.PATENTS.PUBLICATIONS
    WHERE  "assignee_harmonized"::STRING ILIKE '%DENSO CORP%'
      AND  "filing_date" > 0
),
citing_raw AS (            -- step-2/3/4
    SELECT DISTINCT
           t."publication_number"                        AS citing_pub,
           c.value:"code"::STRING                        AS first_cpc,
           f.value:"name"::STRING                        AS citing_assignee
    FROM   PATENTS.PATENTS.PUBLICATIONS            t
           , LATERAL FLATTEN(input => t."citation")      cit
           , LATERAL FLATTEN(input => t."assignee_harmonized") f
           , LATERAL FLATTEN(input => t."cpc")           c
    WHERE  cit.value:"publication_number"::STRING IN (SELECT "publication_number" FROM denso_pubs)
      AND  f.value:"name"::STRING NOT ILIKE '%DENSO CORP%'   -- exclude DENSO as citer
      AND  c.value:"first"::BOOLEAN = TRUE                   -- primary CPC only
),
agg AS (                   -- step-5
    SELECT
           citing_assignee,
           first_cpc,
           COUNT(*)                                         AS citation_count
    FROM   citing_raw
    GROUP BY citing_assignee,
             first_cpc
)
SELECT
       a.citing_assignee,
       d."titleFull"                                        AS cpc_title_full,
       a.citation_count
FROM   agg                     a
LEFT  JOIN PATENTS.PATENTS.CPC_DEFINITION d
       ON d."symbol" = a.first_cpc
ORDER BY citation_count DESC NULLS LAST;