WITH cpc_filtered AS (          -- publications that contain at least one CPC symbol starting with 'A01B3'
    SELECT
        p."publication_number"                                      AS publication_number,
        p."country_code"                                            AS country_code,
        TRY_TO_NUMBER(LEFT(p."filing_date"::TEXT, 4))               AS filing_year,
        ah.value:"name"::STRING                                     AS assignee_name
    FROM PATENTS.PATENTS.PUBLICATIONS p
         , LATERAL FLATTEN(input => p."cpc")                        c
         , LATERAL FLATTEN(input => p."assignee_harmonized")        ah
    WHERE c.value:"code"::STRING LIKE 'A01B3%'      -- class A01B3…
      AND p."filing_date" IS NOT NULL
      AND ah.value:"name" IS NOT NULL
),
app_data AS (                   -- one row per (assignee, publication)
    SELECT DISTINCT
        assignee_name,
        publication_number,
        country_code,
        filing_year
    FROM cpc_filtered
),
assignee_totals AS (            -- total applications per assignee
    SELECT
        assignee_name,
        COUNT(*) AS total_apps
    FROM app_data
    GROUP BY assignee_name
),
top_assignees AS (              -- keep only top‑3
    SELECT *
    FROM assignee_totals
    ORDER BY total_apps DESC NULLS LAST, assignee_name
    LIMIT 3
),
assignee_year AS (              -- yearly counts for those assignees
    SELECT
        a.assignee_name,
        a.filing_year,
        COUNT(*) AS apps_in_year
    FROM app_data a
    JOIN top_assignees t
      ON a.assignee_name = t.assignee_name
    GROUP BY a.assignee_name, a.filing_year
),
peak_years AS (                 -- pick the peak year per assignee
    SELECT
        assignee_name,
        filing_year  AS peak_year,
        apps_in_year,
        ROW_NUMBER() OVER (PARTITION BY assignee_name
                           ORDER BY apps_in_year DESC, filing_year) AS rn
    FROM assignee_year
),
peak_years_top AS (
    SELECT assignee_name, peak_year, apps_in_year
    FROM   peak_years
    WHERE  rn = 1
),
country_split AS (              -- country distribution in the peak year
    SELECT
        a.assignee_name,
        a.filing_year,
        a.country_code,
        COUNT(*) AS apps_country_year
    FROM app_data a
    JOIN peak_years_top p
      ON a.assignee_name = p.assignee_name
     AND a.filing_year   = p.peak_year
    GROUP BY a.assignee_name, a.filing_year, a.country_code
),
top_country AS (                -- top country for each assignee in that year
    SELECT
        assignee_name,
        country_code,
        ROW_NUMBER() OVER (PARTITION BY assignee_name
                           ORDER BY apps_country_year DESC, country_code) AS rn
    FROM country_split
)
SELECT
    t.assignee_name     AS "ASSIGNEE",
    t.total_apps        AS "TOTAL_APPLICATIONS",
    p.peak_year         AS "YEAR_WITH_MOST_APPLICATIONS",
    p.apps_in_year      AS "APPLICATIONS_IN_PEAK_YEAR",
    c.country_code      AS "TOP_COUNTRY_CODE_IN_PEAK_YEAR"
FROM top_assignees  t
JOIN peak_years_top p ON t.assignee_name = p.assignee_name
JOIN top_country    c ON t.assignee_name = c.assignee_name
WHERE c.rn = 1
ORDER BY t.total_apps DESC NULLS LAST, t.assignee_name;