WITH denso_pubs AS (   -- patents assigned to DENSO CORP that can be cited
    SELECT DISTINCT p."publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."assignee_harmonized") ah
    WHERE ah.value:"name"::STRING ILIKE '%DENSO CORP%'
      AND p."filing_date" IS NOT NULL
      AND p."filing_date" > 0
),
citing_info AS (       -- publications that cite the DENSO patents
    SELECT
        cpub."publication_number"                      AS "citing_pub",
        ah.value:"name"::STRING                        AS "citing_assignee"
    FROM PATENTS.PATENTS.PUBLICATIONS cpub,
         LATERAL FLATTEN(input => cpub."citation") cite,
         LATERAL FLATTEN(input => cpub."assignee_harmonized") ah
    WHERE cite.value:"publication_number"::STRING IN (SELECT "publication_number" FROM denso_pubs)
      AND cpub."filing_date" IS NOT NULL
      AND cpub."filing_date" > 0
      AND ah.value:"name"::STRING NOT ILIKE '%DENSO CORP%'      -- exclude DENSO as citer
),
citing_cpc AS (        -- first CPC code (primary) for each citing publication
    SELECT
        ci."citing_pub",
        SUBSTR(cpc_elem.value:"code"::STRING, 1, 4)    AS "cpc4"
    FROM citing_info ci
    JOIN PATENTS.PATENTS.PUBLICATIONS pub
      ON pub."publication_number" = ci."citing_pub",
         LATERAL FLATTEN(input => pub."cpc") cpc_elem
    WHERE cpc_elem.index = 0                           -- first CPC only
),
combined AS (          -- map CPC subclass to its full title
    SELECT
        ci."citing_assignee",
        COALESCE(cd."titleFull", 'UNKNOWN CPC TITLE')  AS "cpc_title"
    FROM citing_info ci
    JOIN citing_cpc cc
      ON cc."citing_pub" = ci."citing_pub"
    LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION cd
      ON cd."symbol" = cc."cpc4"
)
SELECT
    "citing_assignee",
    "cpc_title",
    COUNT(*) AS "citation_count"
FROM combined
GROUP BY "citing_assignee", "cpc_title"
ORDER BY "citation_count" DESC NULLS LAST;