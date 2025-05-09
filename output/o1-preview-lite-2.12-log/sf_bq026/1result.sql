WITH
assignee_patents AS (
    SELECT
        t."publication_number",
        a.value:"name"::STRING AS "ASSIGNEE_NAME",
        TO_VARCHAR(TRY_TO_DATE(t."filing_date"::VARCHAR, 'YYYYMMDD'), 'YYYY') AS "FILING_YEAR",
        t."country_code"
    FROM PATENTS.PATENTS.PUBLICATIONS t
    , LATERAL FLATTEN(input => t."cpc") c
    , LATERAL FLATTEN(input => t."assignee_harmonized") a
    WHERE c.value:"code"::STRING LIKE 'A61%'
      AND a.value:"name"::STRING IS NOT NULL
      AND TRY_TO_DATE(t."filing_date"::VARCHAR, 'YYYYMMDD') IS NOT NULL
),
top_assignee AS (
    SELECT "ASSIGNEE_NAME",
           COUNT(DISTINCT "publication_number") AS "patent_count"
    FROM assignee_patents
    GROUP BY "ASSIGNEE_NAME"
    ORDER BY "patent_count" DESC NULLS LAST
    LIMIT 1
),
busiest_year AS (
    SELECT "FILING_YEAR",
           COUNT(DISTINCT "publication_number") AS "patent_count"
    FROM assignee_patents
    WHERE "ASSIGNEE_NAME" = (SELECT "ASSIGNEE_NAME" FROM top_assignee)
    GROUP BY "FILING_YEAR"
    ORDER BY "patent_count" DESC NULLS LAST
    LIMIT 1
),
top_jurisdictions AS (
    SELECT "country_code",
           COUNT(DISTINCT "publication_number") AS "patent_count"
    FROM assignee_patents
    WHERE "ASSIGNEE_NAME" = (SELECT "ASSIGNEE_NAME" FROM top_assignee)
      AND "FILING_YEAR" = (SELECT "FILING_YEAR" FROM busiest_year)
    GROUP BY "country_code"
    ORDER BY "patent_count" DESC NULLS LAST
    LIMIT 5
)
SELECT LISTAGG("country_code", ',') AS "Jurisdiction_Codes"
FROM top_jurisdictions;