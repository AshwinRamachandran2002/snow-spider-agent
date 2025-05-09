/*  Which assignees (excluding DENSO CORP itself) have cited patents
    assigned to DENSO, and what CPC subclasses (title of the FIRST CPC
    code) are associated with those citations?                               */

WITH denso_pubs AS (          -- all publications whose assignee contains “DENSO”
    SELECT DISTINCT
           p."publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN ( INPUT => p."assignee_harmonized") ah
    WHERE UPPER(ah.value:"name"::STRING) LIKE '%DENSO%'
),

citing_data AS (              -- expand citing publications and keep FIRST CPC only
    SELECT
        c_pub."publication_number"                           AS "citing_pub",
        ca.value:"name"::STRING                              AS "citing_assignee",
        cc.value:"code"::STRING                              AS "primary_cpc",
        cit.value:"publication_number"::STRING               AS "cited_pub"
    FROM PATENTS.PATENTS.PUBLICATIONS             c_pub
         , LATERAL FLATTEN (INPUT => c_pub."assignee_harmonized") ca
         , LATERAL FLATTEN (INPUT => c_pub."cpc")            cc
         , LATERAL FLATTEN (INPUT => c_pub."citation")       cit
    WHERE c_pub."filing_date" > 0                   -- insure valid filing date
      AND cc.value:"first"::BOOLEAN = TRUE          -- keep primary CPC code
      AND UPPER(ca.value:"name"::STRING) NOT LIKE '%DENSO%'   -- exclude DENSO as citer
)

SELECT
    cd."titleFull"                     AS "cpc_title",
    c."citing_assignee",
    COUNT(*)                           AS "citation_count"
FROM citing_data c
JOIN denso_pubs d
  ON c."cited_pub" = d."publication_number"
JOIN PATENTS.PATENTS.CPC_DEFINITION cd
  ON cd."symbol" = c."primary_cpc"
GROUP BY
    c."citing_assignee",
    cd."titleFull"
ORDER BY
    "citation_count" DESC NULLS LAST;