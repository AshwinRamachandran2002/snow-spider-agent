/*  Which assignees (excluding DENSO CORP) cite DENSO-assigned patents,
    and what are the titles of the primary CPC subclasses for those citations?  */

WITH denso_pubs AS (        -- 1) DENSO-assigned publications with a valid filing date
    SELECT DISTINCT
           "publication_number"
    FROM   PATENTS.PATENTS.PUBLICATIONS
    WHERE  "assignee_harmonized" ILIKE '%DENSO%CORP%'
      AND  "filing_date" > 0
),

citing_links AS (           -- 2) All citing publications (valid filing date) that cite a DENSO pub
    SELECT DISTINCT
           cit."publication_number" AS "citing_pub"
    FROM   PATENTS.PATENTS.PUBLICATIONS  cit,
           LATERAL FLATTEN (INPUT => cit."citation") cited
    WHERE  cited.value:"publication_number"::STRING IN (SELECT * FROM denso_pubs)
      AND  cit."filing_date" > 0
),

citing_details AS (         -- 3) Bring in assignee + first CPC code, exclude DENSO as citer
    SELECT
           p."publication_number"    AS "citing_pub",
           p."assignee_harmonized"   AS "citing_assignee",
           cpc_item.value:"code"::STRING AS "first_cpc"
    FROM   PATENTS.PATENTS.PUBLICATIONS  p
           JOIN citing_links  cl
             ON p."publication_number" = cl."citing_pub",
           LATERAL FLATTEN (INPUT => p."cpc") cpc_item
    WHERE  cpc_item.index = 0
      AND  p."assignee_harmonized" NOT ILIKE '%DENSO%CORP%'
),

add_title AS (              -- 4) Map CPC code → full CPC subclass title
    SELECT
           cd."citing_assignee",
           def."titleFull"          AS "cpc_title",
           cd."citing_pub"
    FROM   citing_details cd
           LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION def
                  ON def."symbol" = cd."first_cpc"
)

-- 5) Final aggregation
SELECT
       "citing_assignee",
       "cpc_title",
       COUNT(*) AS "citation_cnt"
FROM   add_title
GROUP BY
       "citing_assignee",
       "cpc_title"
ORDER BY
       "citation_cnt" DESC NULLS LAST;