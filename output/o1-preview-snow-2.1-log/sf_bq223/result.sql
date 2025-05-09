WITH denso_patents AS (
    SELECT DISTINCT t."publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS t,
    LATERAL FLATTEN(input => t."assignee_harmonized") assignee
    WHERE assignee.value:"name"::STRING ILIKE '%DENSO CORP%'
),
citations_to_denso AS (
    SELECT t."publication_number" AS "citing_patent_number",
           assignee.value:"name"::STRING AS "citing_assignee_name",
           SUBSTR(cpc_code.value:"code"::STRING, 1, 4) AS "cpc_subclass"
    FROM PATENTS.PATENTS.PUBLICATIONS t,
    LATERAL FLATTEN(input => t."assignee_harmonized") assignee,
    LATERAL FLATTEN(input => t."citation") cited,
    LATERAL FLATTEN(input => t."cpc") cpc_code
    WHERE cited.value:"publication_number"::STRING IN (
        SELECT "publication_number" FROM denso_patents
    )
    AND assignee.value:"name"::STRING NOT ILIKE '%DENSO CORP%'
    AND cpc_code.value:"first"::BOOLEAN = TRUE
),
cpc_subclasses AS (
    SELECT "symbol", "titleFull"
    FROM PATENTS.PATENTS.CPC_DEFINITION
    WHERE LENGTH("symbol") = 4
),
citations_with_cpc_title AS (
    SELECT ctd."citing_assignee_name",
           ctd."cpc_subclass",
           cpc_def."titleFull" AS "cpc_subclass_title"
    FROM citations_to_denso ctd
    LEFT JOIN cpc_subclasses cpc_def
    ON cpc_def."symbol" = ctd."cpc_subclass"
)

SELECT "citing_assignee_name" AS "Assignee",
       "cpc_subclass_title" AS "CPC_Subclass_Title",
       COUNT(*) AS "Citation_Count"
FROM citations_with_cpc_title
GROUP BY "citing_assignee_name", "cpc_subclass_title";