WITH filtered AS (
    SELECT
        UPPER(TRIM(a.value:"name"::string))        AS assignee,
        p."country_code"                           AS country_code,
        TO_NUMBER(SUBSTR(p."publication_date"::string,1,4)) AS year
    FROM PATENTS.PATENTS.PUBLICATIONS p
         ,LATERAL FLATTEN(input => p."cpc")                c
         ,LATERAL FLATTEN(input => p."assignee_harmonized") a
    WHERE c.value:"code"::string LIKE 'A01B3%'          -- CPC class A01B3
      AND p."publication_date" IS NOT NULL
      AND a.value:"name" IS NOT NULL
),
assignee_year_country AS (
    SELECT
        assignee,
        year,
        country_code,
        COUNT(*) AS apps
    FROM filtered
    GROUP BY assignee, year, country_code
),
assignee_year AS (
    SELECT
        assignee,
        year,
        SUM(apps) AS year_apps
    FROM assignee_year_country
    GROUP BY assignee, year
),
assignee_top_year AS (        -- year with the most applications for every assignee
    SELECT assignee, year, year_apps
    FROM (
        SELECT
            assignee,
            year,
            year_apps,
            ROW_NUMBER() OVER (PARTITION BY assignee
                               ORDER BY year_apps DESC, year ASC) AS rn
        FROM assignee_year
    )
    WHERE rn = 1
),
country_in_top_year AS (      -- top country in that peak year
    SELECT
        ay.assignee,
        ay.year,
        cy.country_code AS top_country
    FROM assignee_top_year ay
    JOIN assignee_year_country cy
         ON cy.assignee = ay.assignee
        AND cy.year      = ay.year
    QUALIFY ROW_NUMBER() OVER (PARTITION BY ay.assignee
                               ORDER BY cy.apps DESC, cy.country_code ASC) = 1
),
assignee_total AS (           -- total applications per assignee
    SELECT
        assignee,
        SUM(year_apps) AS total_apps
    FROM assignee_year
    GROUP BY assignee
),
combined AS (
    SELECT
        at.assignee,
        at.total_apps,
        ay.year,
        ay.year_apps,
        cty.top_country
    FROM assignee_total      at
    JOIN assignee_top_year   ay  ON ay.assignee  = at.assignee
    JOIN country_in_top_year cty ON cty.assignee = at.assignee
)
SELECT
    assignee        AS "Assignee",
    total_apps      AS "Total Applications",
    year            AS "Peak Year",
    year_apps       AS "Applications in Peak Year",
    top_country     AS "Top Country Code in Peak Year"
FROM combined
ORDER BY total_apps DESC NULLS LAST, assignee
LIMIT 3;