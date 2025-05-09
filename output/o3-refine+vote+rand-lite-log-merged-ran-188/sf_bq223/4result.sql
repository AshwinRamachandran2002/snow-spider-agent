/*  Which assignees (excluding DENSO itself) have cited patents assigned to  
    DENSO CORP, and what CPC subclasses (first-CPC only) are those citations
    associated with?   */
SELECT
       ci."citing_assignee",
       COALESCE(def."titleFull", ci."primary_cpc_code") AS "primary_cpc_title",
       COUNT(*)                                         AS "citation_count"
FROM  (
        /* ---- one row per (citation link  ×  citing-patent’s primary CPC) ---- */
        SELECT
               ah1.value:"name"::STRING    AS "citing_assignee",
               cpc_f.value:"code"::STRING  AS "primary_cpc_code"
        FROM   PATENTS.PATENTS.PUBLICATIONS              citing
        ,      LATERAL FLATTEN (input => citing."citation")                cited
        ,      PATENTS.PATENTS.PUBLICATIONS              cited_doc
        ,      LATERAL FLATTEN (input => cited_doc."assignee_harmonized")  ah2
        ,      LATERAL FLATTEN (input => citing."assignee_harmonized")     ah1
        ,      LATERAL FLATTEN (input => citing."cpc")                     cpc_f
        WHERE  cited_doc."publication_number" = cited.value:"publication_number"::STRING
          /* --- cited patent must be assigned to DENSO CORP ------------------- */
          AND   ah2.value:"name"::STRING ILIKE 'DENSO CORP%'
          /* --- exclude any citer whose assignee contains “DENSO” ------------- */
          AND   ah1.value:"name"::STRING NOT ILIKE '%DENSO%'
          /* --- keep only the primary (first=true) CPC of the citing patent --- */
          AND   cpc_f.value:"first"::BOOLEAN = TRUE
          /* --- disregard records without a valid filing date ----------------- */
          AND   citing."filing_date" > 0
      )  ci
LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION def
       ON def."symbol" = ci."primary_cpc_code"
GROUP BY
       ci."citing_assignee",
       def."titleFull",
       ci."primary_cpc_code"
ORDER BY
       "citation_count" DESC NULLS LAST;