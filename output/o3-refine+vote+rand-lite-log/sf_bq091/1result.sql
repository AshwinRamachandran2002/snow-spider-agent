WITH pub_filtered AS (           -- all applications whose CPC code begins with 'A61'
    SELECT DISTINCT
        p."publication_number",
        p."filing_date",
        TO_NUMBER(LEFT(TO_VARCHAR(p."filing_date"),4))  AS filing_year,
        ah.value:"name"::STRING                         AS assignee_name
    FROM PATENTS.PATENTS.PUBLICATIONS p
         , LATERAL FLATTEN(input => p."assignee_harmonized") ah
         , LATERAL FLATTEN(input => p."cpc")            c
    WHERE c.value:"code"::STRING ILIKE 'A61%'           -- CPC category filter
      AND p."filing_date" IS NOT NULL
      AND ah.value:"name" IS NOT NULL
),

assignee_year_counts AS (        -- application counts per assignee & year
    SELECT
        assignee_name,
        filing_year,
        COUNT(*) AS apps_in_year
    FROM   pub_filtered
    GROUP  BY assignee_name, filing_year
),

top_assignee AS (                -- assignee with the most A61 applications
    SELECT assignee_name
    FROM (
        SELECT
            assignee_name,
            SUM(apps_in_year) AS total_apps,
            ROW_NUMBER() OVER (ORDER BY SUM(apps_in_year) DESC NULLS LAST, assignee_name) AS rn
        FROM assignee_year_counts
        GROUP BY assignee_name
    )
    WHERE rn = 1
),

yearly_max AS (                  -- yearly counts for that assignee
    SELECT
        ayc.filing_year,
        ayc.apps_in_year,
        ROW_NUMBER() OVER (ORDER BY ayc.apps_in_year DESC NULLS LAST, ayc.filing_year) AS rn
    FROM   assignee_year_counts ayc
    JOIN   top_assignee ta
      ON   ayc.assignee_name = ta.assignee_name
)

SELECT filing_year AS "YEAR"     -- year with the highest number of filings
FROM   yearly_max
WHERE  rn = 1;