/*  Assignees (excluding DENSO CORP itself) that cite DENSO-owned patents,
    together with the full title of the primary CPC subclass (1st CPC code)
    and the number of such citations.                                          */

WITH denso_pubs AS (      -- 1.  Publication numbers of patents assigned to DENSO
    SELECT DISTINCT
           d."publication_number"
    FROM   PATENTS.PATENTS."PUBLICATIONS" d,
           LATERAL FLATTEN (INPUT => d."assignee_harmonized") dah
    WHERE  dah.value:"name"::STRING ILIKE '%DENSO%'    -- DENSO assignee
      AND  d."filing_date" > 0                         -- valid filing date
),

citing_rows AS (          -- 2.  All (citing-assignee, first-CPC, citation) rows
    SELECT
        ah.value:"name"::STRING                           AS citing_assignee,
        LEFT(pc.value:"code"::STRING, 4)                  AS cpc4,
        cd."titleFull"                                    AS cpc_title
    FROM   PATENTS.PATENTS."PUBLICATIONS" p
           CROSS JOIN LATERAL FLATTEN (INPUT => p."citation")             ct
           CROSS JOIN LATERAL FLATTEN (INPUT => p."assignee_harmonized")  ah
           CROSS JOIN LATERAL FLATTEN (INPUT => p."cpc")                  pc
           LEFT  JOIN PATENTS.PATENTS."CPC_DEFINITION"        cd
                  ON cd."symbol" = LEFT(pc.value:"code"::STRING, 4)
    WHERE  ct.value:"publication_number"::STRING IN (SELECT * FROM denso_pubs)
      AND  pc.value:"first"::BOOLEAN = TRUE              -- primary CPC only
      AND  p."filing_date" > 0                           -- citing patent valid date
      AND  ah.value:"name"::STRING NOT ILIKE '%DENSO%'   -- exclude DENSO as citer
)

-- 3.  Aggregate to (citing assignee × CPC title)
SELECT
    citing_assignee,
    cpc_title,
    COUNT(*)                              AS citation_count
FROM citing_rows
GROUP BY
    citing_assignee,
    cpc_title
ORDER BY
    citation_count DESC NULLS LAST;