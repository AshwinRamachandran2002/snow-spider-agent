WITH denso_pubs AS (   -- DENSO‑assigned patents with a valid filing date
    SELECT DISTINCT p."publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."assignee_harmonized") ah
    WHERE ah.value:"name"::STRING ILIKE '%DENSO%CORP%'
      AND p."filing_date" > 0
), 

citing_rows AS (       -- explode citing patents to (assignee × first‑CPC × cited pub)
    SELECT
        p."publication_number"                     AS citing_pub,
        ah_citing.value:"name"::STRING             AS citing_assignee_name,
        cpc_first.value:"code"::STRING             AS primary_cpc_code,
        cit.value:"publication_number"::STRING     AS cited_pub
    FROM PATENTS.PATENTS.PUBLICATIONS p
         , LATERAL FLATTEN(input => p."assignee_harmonized") ah_citing
         , LATERAL FLATTEN(input => p."citation") cit
         , LATERAL FLATTEN(input => p."cpc", OUTER => TRUE) cpc_first
    WHERE cpc_first."INDEX" = 0                    -- only the first CPC code
      AND p."filing_date" > 0                      -- valid filing date on citing side
), 

filtered AS (        -- keep only citations that point to a DENSO patent
    SELECT
        cr.citing_assignee_name,
        cr.primary_cpc_code
    FROM citing_rows cr
    WHERE cr.cited_pub IN (SELECT "publication_number" FROM denso_pubs)
      AND cr.citing_assignee_name IS NOT NULL
      AND cr.primary_cpc_code IS NOT NULL
      AND cr.citing_assignee_name NOT ILIKE '%DENSO%CORP%'   -- exclude DENSO as citer
)

SELECT
    f.citing_assignee_name                      AS citing_assignee,
    cd."titleFull"                              AS cpc_subclass_title,
    COUNT(*)                                    AS citation_count
FROM filtered f
LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION cd
       ON cd."symbol" = f.primary_cpc_code
GROUP BY f.citing_assignee_name, cd."titleFull"
ORDER BY citation_count DESC NULLS LAST, citing_assignee ASC;