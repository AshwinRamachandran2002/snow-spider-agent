/* ------------------------------------------------------------------------
   Citing assignees (excluding DENSO CORP) that cite patents assigned to
   DENSO CORP, together with the full title of the primary CPC subclass
   (derived from the first CPC code) and a count of such citations.
-------------------------------------------------------------------------*/
WITH citing AS (   -- patents that make citations
    SELECT  pub."publication_number"         AS citing_pub,
            pub."assignee_harmonized"        AS citing_assignee_var,
            pub."cpc"                        AS citing_cpc_var,
            pub."filing_date",
            cit.value                        AS cited_var
    FROM   PATENTS.PATENTS.PUBLICATIONS  pub,
           LATERAL FLATTEN(INPUT => pub."citation") cit
    WHERE  pub."filing_date" IS NOT NULL            -- valid filing date
           AND pub."filing_date" > 0
), cited AS (      -- pick the cited‑patent publication number
    SELECT  c.*,
            cited_var:"publication_number"::TEXT AS cited_pub
    FROM    citing  c
), denso_cited AS (  -- retain only those citations where the cited patent
                     -- is assigned to DENSO CORP
    SELECT  d.*,
            p."assignee_harmonized"  AS cited_assignee_var
    FROM    cited  d
    JOIN    PATENTS.PATENTS.PUBLICATIONS  p
           ON p."publication_number" = d.cited_pub
    WHERE   p."assignee_harmonized" IS NOT NULL
            AND LOWER(p."assignee_harmonized"::STRING) LIKE '%denso corp%'
), filtered AS (   -- drop citations made by DENSO CORP itself
    SELECT *
    FROM   denso_cited
    WHERE  citing_assignee_var IS NOT NULL
           AND LOWER(citing_assignee_var::STRING) NOT LIKE '%denso corp%'
), pcpc AS (       -- choose the primary CPC code of the citing patent
    SELECT  f.*,
            cpc_item.value:"code"::TEXT                            AS cpc_code,
            ROW_NUMBER() OVER (PARTITION BY f.citing_pub
                               ORDER BY
                                   CASE WHEN cpc_item.value:"first"::BOOLEAN
                                              = TRUE THEN 0 ELSE 1 END,
                                   cpc_item.index)                AS rn
    FROM   filtered  f,
           LATERAL FLATTEN(INPUT => f.citing_cpc_var) cpc_item
), first_cpc AS (  -- keep only the first / main CPC code per citing patent
    SELECT *
    FROM   pcpc
    WHERE  rn = 1
), subclass AS (   -- derive the CPC subclass (first 4 characters)
    SELECT  *,
            SUBSTR(cpc_code,1,4) AS subclass_code
    FROM    first_cpc
), with_title AS ( -- attach the full title of the CPC subclass
    SELECT  s.*,
            d."titleFull" AS subclass_title_full
    FROM    subclass  s
    LEFT JOIN PATENTS.PATENTS.CPC_DEFINITION  d
           ON d."symbol" = s.subclass_code
)
SELECT
    TRIM(with_title.citing_assignee_var[0]:"name"::TEXT)  AS citing_assignee,
    COALESCE(with_title.subclass_title_full,
             with_title.subclass_code)                    AS cpc_subclass_title,
    COUNT(*)                                              AS citation_count
FROM   with_title
GROUP  BY citing_assignee, cpc_subclass_title
ORDER BY citation_count DESC NULLS LAST,
         citing_assignee;