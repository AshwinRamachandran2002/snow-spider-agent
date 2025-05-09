WITH cte AS (  /* publications whose CPC symbol starts with A01B3 */
    SELECT DISTINCT
        p."application_number"                        AS app_no,
        p."country_code"                              AS country_code,
        p."publication_date"                          AS pub_date,
        TRIM(ah.value:"name"::string)                 AS assignee
    FROM PATENTS.PATENTS.PUBLICATIONS  p,
         LATERAL FLATTEN( INPUT => p."cpc")                       c,
         LATERAL FLATTEN( INPUT => p."assignee_harmonized")       ah
    WHERE c.value:"code"::string LIKE 'A01B3%'
      AND ah.value:"name" IS NOT NULL
),
cte2 AS (  /* one record per (assignee , application) */
    SELECT
        assignee,
        app_no,
        MIN(pub_date)     AS first_pub_date,
        MIN(country_code) AS country_code
    FROM cte
    GROUP BY assignee, app_no
),
assignee_tot AS (
    SELECT
        assignee,
        COUNT(DISTINCT app_no) AS total_apps
    FROM cte2
    GROUP BY assignee
),
top3 AS (
    SELECT assignee, total_apps
    FROM assignee_tot
    ORDER BY total_apps DESC NULLS LAST, assignee
    LIMIT 3
),
yearly AS (
    SELECT
        t.assignee,
        TO_NUMBER(LEFT(first_pub_date::string, 4))     AS yr,
        COUNT(DISTINCT app_no)                         AS apps_in_year
    FROM cte2
    JOIN top3 t  ON t.assignee = cte2.assignee
    GROUP BY t.assignee, yr
),
peak_year AS (  /* year with most applications for each assignee */
    SELECT
        assignee,
        yr,
        apps_in_year,
        ROW_NUMBER() OVER (PARTITION BY assignee
                           ORDER BY apps_in_year DESC, yr) AS rn
    FROM yearly
),
country_year AS (  /* country split within each peak‑year candidate */
    SELECT
        t.assignee,
        TO_NUMBER(LEFT(first_pub_date::string, 4))     AS yr,
        country_code,
        COUNT(DISTINCT app_no)                         AS apps_in_country
    FROM cte2
    JOIN top3 t  ON t.assignee = cte2.assignee
    GROUP BY t.assignee, yr, country_code
),
peak_country AS (  /* dominant country during the peak year */
    SELECT
        cy.assignee,
        cy.country_code,
        cy.apps_in_country,
        ROW_NUMBER() OVER (PARTITION BY cy.assignee
                           ORDER BY cy.apps_in_country DESC, cy.country_code) AS rn
    FROM country_year  cy
    JOIN peak_year     py
         ON py.assignee = cy.assignee
        AND py.yr       = cy.yr
    WHERE py.rn = 1
)
SELECT
    t.assignee                          AS "ASSIGNEE",
    t.total_apps                        AS "TOTAL_APPLICATIONS",
    py.yr                               AS "PEAK_YEAR",
    py.apps_in_year                     AS "APPLICATIONS_IN_PEAK_YEAR",
    pc.country_code                     AS "TOP_COUNTRY_CODE"
FROM top3         t
JOIN peak_year    py ON py.assignee = t.assignee AND py.rn = 1
JOIN peak_country pc ON pc.assignee = t.assignee AND pc.rn = 1
ORDER BY t.total_apps DESC NULLS LAST, t.assignee;