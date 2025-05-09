WITH a01b3_publications AS (                -- all publications with a CPC symbol beginning A01B3
    SELECT
        p."application_number"                          AS app_no,
        p."filing_date"                                 AS filing_date,
        p."country_code"                                AS country_code,
        UPPER(TRIM(ah.value:"name"::STRING))            AS assignee
    FROM PATENTS.PATENTS.PUBLICATIONS p
         ,LATERAL FLATTEN(input => p."cpc")             c
         ,LATERAL FLATTEN(input => p."assignee_harmonized") ah
    WHERE c.value:"code"::STRING LIKE 'A01B3%'
      AND ah.value:"name" IS NOT NULL
),
top_assignees AS (                      -- top‑3 assignees by total applications
    SELECT
        assignee,
        COUNT(DISTINCT app_no) AS total_applications
    FROM a01b3_publications
    GROUP BY assignee
    ORDER BY total_applications DESC NULLS LAST, assignee
    LIMIT 3
),
apps_per_year AS (                      -- yearly application counts for those assignees
    SELECT
        ap.assignee,
        SUBSTRING(TO_VARCHAR(ap.filing_date),1,4) AS year,
        COUNT(DISTINCT ap.app_no) AS apps_in_year
    FROM a01b3_publications ap
    JOIN top_assignees ta ON ta.assignee = ap.assignee
    WHERE ap.filing_date > 0
    GROUP BY ap.assignee, SUBSTRING(TO_VARCHAR(ap.filing_date),1,4)
),
peak_year AS (                          -- most active year per assignee
    SELECT
        assignee,
        year                              AS peak_year,
        apps_in_year                      AS applications_in_peak_year
    FROM (
        SELECT
            *,
            ROW_NUMBER() OVER (PARTITION BY assignee
                               ORDER BY apps_in_year DESC, year) AS rn
        FROM apps_per_year
    )
    WHERE rn = 1
),
country_rank AS (                       -- country ranking within the peak year
    SELECT
        ap.assignee,
        ap.country_code,
        COUNT(DISTINCT ap.app_no) AS apps_cnt,
        ROW_NUMBER() OVER (PARTITION BY ap.assignee
                           ORDER BY COUNT(DISTINCT ap.app_no) DESC, ap.country_code) AS rn
    FROM a01b3_publications ap
    JOIN peak_year py
      ON py.assignee = ap.assignee
     AND SUBSTRING(TO_VARCHAR(ap.filing_date),1,4) = py.peak_year
    GROUP BY ap.assignee, ap.country_code
),
peak_year_country AS (                  -- top country in the peak year
    SELECT
        assignee,
        country_code AS country_code_in_peak_year
    FROM country_rank
    WHERE rn = 1
)
SELECT
    ta.assignee                                   AS assignee,
    ta.total_applications                         AS total_applications,
    py.peak_year                                  AS peak_year,
    py.applications_in_peak_year                  AS applications_in_peak_year,
    pc.country_code_in_peak_year                  AS country_code_in_peak_year
FROM top_assignees     ta
JOIN peak_year         py ON py.assignee = ta.assignee
JOIN peak_year_country pc ON pc.assignee = ta.assignee
ORDER BY ta.total_applications DESC NULLS LAST, ta.assignee;