WITH most_active_assignee AS (
  SELECT
    assignee_f.value:"name"::STRING AS "assignee_name",
    COUNT(DISTINCT t."publication_number") AS "patent_count"
  FROM
    "PATENTS"."PATENTS"."PUBLICATIONS" t,
    LATERAL FLATTEN(input => t."assignee_harmonized") assignee_f,
    LATERAL FLATTEN(input => t."cpc") cpc_f
  WHERE
    SUBSTRING(cpc_f.value:"code"::STRING, 1, 3) = 'A61'
  GROUP BY
    assignee_f.value:"name"::STRING
  ORDER BY
    "patent_count" DESC NULLS LAST
  LIMIT 1
),
busiest_year AS (
  SELECT
    SUBSTRING(TO_CHAR(t."filing_date"), 1, 4) AS "filing_year",
    COUNT(DISTINCT t."publication_number") AS "patent_count"
  FROM
    "PATENTS"."PATENTS"."PUBLICATIONS" t,
    LATERAL FLATTEN(input => t."assignee_harmonized") assignee_f,
    LATERAL FLATTEN(input => t."cpc") cpc_f,
    most_active_assignee maa
  WHERE
    SUBSTRING(cpc_f.value:"code"::STRING, 1, 3) = 'A61'
    AND assignee_f.value:"name"::STRING = maa."assignee_name"
    AND t."filing_date" IS NOT NULL AND t."filing_date" > 0
  GROUP BY
    SUBSTRING(TO_CHAR(t."filing_date"), 1, 4)
  ORDER BY
    "patent_count" DESC NULLS LAST
  LIMIT 1
),
top_jurisdictions AS (
  SELECT
    t."country_code",
    COUNT(DISTINCT t."publication_number") AS "patent_count"
  FROM
    "PATENTS"."PATENTS"."PUBLICATIONS" t,
    LATERAL FLATTEN(input => t."assignee_harmonized") assignee_f,
    LATERAL FLATTEN(input => t."cpc") cpc_f,
    most_active_assignee maa,
    busiest_year byear
  WHERE
    SUBSTRING(cpc_f.value:"code"::STRING, 1, 3) = 'A61'
    AND assignee_f.value:"name"::STRING = maa."assignee_name"
    AND SUBSTRING(TO_CHAR(t."filing_date"), 1, 4) = byear."filing_year"
  GROUP BY
    t."country_code"
  ORDER BY
    "patent_count" DESC NULLS LAST
  LIMIT 5
)
SELECT
  LISTAGG("country_code", ',') AS "Jurisdiction_Codes"
FROM
  top_jurisdictions;