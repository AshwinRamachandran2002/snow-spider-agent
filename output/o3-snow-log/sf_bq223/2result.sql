/* ---------------------------------------------------------------------------
   Corrected query: list non-DENSO assignees that cite DENSO-assigned patents,
   showing the primary CPC subclass title of the citing patents and the
   number of such citations.
--------------------------------------------------------------------------- */
WITH denso_pubs AS (          /* 1. Patents assigned to DENSO with valid filing dates */
    SELECT DISTINCT p."publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS  p,
         LATERAL FLATTEN(input => p."assignee_harmonized") ah
    WHERE ah.value:"name"::STRING ILIKE '%DENSO%'
      AND p."filing_date" > 0
),
citing_pairs AS (             /* 2. All (citing → cited) pairs from backward citations  */
    SELECT 
        p."publication_number"               AS "citing_publication",
        f.value:"publication_number"::STRING AS "cited_publication"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."citation") f
    WHERE f.value:"publication_number" IS NOT NULL
),
target_citing AS (            /* 3. Publications that cite at least one DENSO patent    */
    SELECT DISTINCT cp."citing_publication"
    FROM citing_pairs cp
    JOIN denso_pubs  dp
      ON cp."cited_publication" = dp."publication_number"
),
citing_assignee AS (          /* 4. Harmonized assignees of the citing publications     */
    SELECT 
        tc."citing_publication",
        ah.value:"name"::STRING AS "citing_assignee"
    FROM target_citing tc
    JOIN PATENTS.PATENTS.PUBLICATIONS pub
      ON pub."publication_number" = tc."citing_publication",
    LATERAL FLATTEN(input => pub."assignee_harmonized") ah
    WHERE ah.value:"name"::STRING NOT ILIKE '%DENSO%'   -- exclude DENSO itself
),
first_cpc AS (                /* 5. First-flagged CPC code of each citing publication   */
    SELECT 
        ca."citing_publication",
        ca."citing_assignee",
        cpc_f.value:"code"::STRING AS "first_cpc_code"
    FROM citing_assignee ca
    JOIN PATENTS.PATENTS.PUBLICATIONS pub
      ON pub."publication_number" = ca."citing_publication",
    LATERAL FLATTEN(input => pub."cpc") cpc_f
    WHERE cpc_f.value:"first"::BOOLEAN = TRUE
),
cpc_with_title AS (           /* 6. Attach CPC subclass title (8-char truncation)       */
    SELECT 
        fc."citing_assignee",
        SUBSTR(fc."first_cpc_code", 1, 8)    AS "cpc_subclass",
        cd."titleFull"                       AS "cpc_title"
    FROM first_cpc fc
    LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION cd
           ON cd."symbol" = SUBSTR(fc."first_cpc_code", 1, 8)
)
SELECT
    cwt."citing_assignee"                    AS "citing_assignee",
    COALESCE(cwt."cpc_title", '')            AS "cpc_subclass_title",
    COUNT(*)                                 AS "citation_count"
FROM cpc_with_title cwt
GROUP BY
    cwt."citing_assignee",
    cwt."cpc_title"
ORDER BY
    "citation_count" DESC NULLS LAST;