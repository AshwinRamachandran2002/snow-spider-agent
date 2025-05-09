WITH denso_pubs AS (                                        -- all publications assigned to DENSO
    SELECT DISTINCT p."publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS p ,
         LATERAL FLATTEN ( INPUT => p."assignee_harmonized") f
    WHERE f.value:"name"::STRING ILIKE '%DENSO%'
),
citations_to_denso AS (                                     -- citing patents + their assignees
    SELECT DISTINCT 
           cp."publication_number"              AS "citing_pub",
           ass_f.value:"name"::STRING           AS "citing_assignee"
    FROM PATENTS.PATENTS.PUBLICATIONS cp ,
         LATERAL FLATTEN ( INPUT => cp."citation")        cit_f ,
         LATERAL FLATTEN ( INPUT => cp."assignee_harmonized") ass_f ,
         denso_pubs
    WHERE cit_f.value:"publication_number"::STRING = denso_pubs."publication_number"
      AND cp."filing_date" > 0                              -- keep only valid filing dates
      AND ass_f.value:"name"::STRING NOT ILIKE '%DENSO%'    -- exclude DENSO as citer
),
primary_cpc AS (                                            -- first / primary CPC code of each citing patent
    SELECT 
           pub."publication_number"            AS "citing_pub",
           cpc_f.value:"code"::STRING          AS "cpc_code"
    FROM PATENTS.PATENTS.PUBLICATIONS pub ,
         LATERAL FLATTEN ( INPUT => pub."cpc") cpc_f
    WHERE cpc_f.value:"first"::BOOLEAN = TRUE
),
joined AS (                                                 -- merge assignee with CPC subclass
    SELECT 
           ctd."citing_assignee",
           SPLIT_PART(pc."cpc_code", '/', 1)   AS "cpc_subclass"
    FROM citations_to_denso ctd
    JOIN primary_cpc      pc
      ON pc."citing_pub" = ctd."citing_pub"
)
SELECT 
       j."citing_assignee",
       COALESCE(cd."titleFull", '')            AS "cpc_subclass_title",
       COUNT(*)                                AS "citation_count"
FROM joined j
LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION cd
       ON cd."symbol" = j."cpc_subclass"
GROUP BY j."citing_assignee", cd."titleFull"
ORDER BY "citation_count" DESC NULLS LAST;