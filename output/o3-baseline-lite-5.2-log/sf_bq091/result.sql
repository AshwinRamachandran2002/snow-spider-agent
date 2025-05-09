WITH cpc_patents AS (
    /* patents whose CPC classification starts with 'A61' */
    SELECT
        p."application_number"                 AS app_no,
        p."filing_date"                        AS filing_date,
        UPPER(ah.value:"name"::string)         AS assignee_name
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc")                 c,
         LATERAL FLATTEN(input => p."assignee_harmonized") ah
    WHERE c.value:"code"::string LIKE 'A61%'
          AND p."filing_date" IS NOT NULL
),
top_assignee AS (
    /* find the assignee with the most A61 applications */
    SELECT assignee_name,
           COUNT(DISTINCT app_no) AS total_apps
    FROM cpc_patents
    GROUP BY assignee_name
    ORDER BY total_apps DESC NULLS LAST, assignee_name
    LIMIT 1
),
assignee_year_counts AS (
    /* for that assignee, count applications by filing year */
    SELECT
        FLOOR(cp.filing_date / 10000) AS year,
        COUNT(DISTINCT cp.app_no)     AS apps_in_year
    FROM cpc_patents cp
    JOIN top_assignee ta
      ON cp.assignee_name = ta.assignee_name
    GROUP BY year
)
SELECT year
FROM assignee_year_counts
ORDER BY apps_in_year DESC NULLS LAST, year
LIMIT 1;