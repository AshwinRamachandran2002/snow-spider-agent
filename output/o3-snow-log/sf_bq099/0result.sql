/* ---------------------------------------------------------
   TOP-3 assignees for CPC subclass A01B3
   ---------------------------------------------------------*/
WITH filtered AS (     /* 1. publications that contain at least one A01B3 CPC */
    SELECT
        /* robust application identifier */
        COALESCE(p."application_number",
                 p."application_number_formatted",
                 p."publication_number")                       AS appl_no ,

        /* filing country */
        p."country_code"                                       AS country_code ,

        /* raw filing date (YYYYMMDD as NUMBER) */
        p."filing_date"                                        AS filing_date ,

        /* first harmonised assignee name if present, otherwise raw */
        COALESCE(
            (p."assignee_harmonized"[0]:"name")::string ,
            (p."assignee"[0])::string
        )                                                      AS assignee_name
    FROM PATENTS.PATENTS."PUBLICATIONS"  p
         ,LATERAL FLATTEN(INPUT => p."cpc") c
    WHERE c.value:"code"::string LIKE 'A01B3%'                -- CPC subclass
      AND COALESCE(
            (p."assignee_harmonized"[0]:"name")::string ,
            (p."assignee"[0])::string
          ) IS NOT NULL
      AND COALESCE(p."application_number",
                   p."application_number_formatted",
                   p."publication_number") IS NOT NULL
),

/* 2. total filings for every assignee */
assignee_totals AS (
    SELECT
        assignee_name,
        COUNT(DISTINCT appl_no)            AS total_apps
    FROM filtered
    GROUP BY assignee_name
),

/* 3. top-3 assignees by volume */
top3 AS (
    SELECT *
    FROM (
        SELECT
            assignee_name,
            total_apps,
            ROW_NUMBER() OVER (ORDER BY total_apps DESC NULLS LAST) AS rn
        FROM assignee_totals
    )
    WHERE rn <= 3
),

/* 4. yearly counts for each top assignee */
yearly AS (
    SELECT
        f.assignee_name,
        CAST(LEFT(f.filing_date::string, 4) AS INT)            AS yr,
        COUNT(DISTINCT f.appl_no)                              AS apps_in_year
    FROM filtered f
    JOIN top3 t            ON f.assignee_name = t.assignee_name
    GROUP BY
        f.assignee_name,
        CAST(LEFT(f.filing_date::string, 4) AS INT)
),

/* 5. best year (max filings, earliest if tie) for each assignee */
best_year_pick AS (
    SELECT
        assignee_name,
        yr,
        apps_in_year
    FROM (
        SELECT
            assignee_name,
            yr,
            apps_in_year,
            ROW_NUMBER() OVER (PARTITION BY assignee_name
                               ORDER BY apps_in_year DESC NULLS LAST,
                                        yr ASC) AS rn
        FROM yearly
    )
    WHERE rn = 1
),

/* 6. within that best year, count filings per country */
country_counts AS (
    SELECT
        f.assignee_name,
        CAST(LEFT(f.filing_date::string, 4) AS INT)            AS yr,
        f.country_code,
        COUNT(DISTINCT f.appl_no)                              AS apps_in_country
    FROM filtered f
    JOIN best_year_pick b
      ON  f.assignee_name = b.assignee_name
      AND CAST(LEFT(f.filing_date::string, 4) AS INT) = b.yr
    GROUP BY
        f.assignee_name,
        CAST(LEFT(f.filing_date::string, 4) AS INT),
        f.country_code
),

/* 7. for each assignee, choose the country with most filings in that year */
best_country_pick AS (
    SELECT
        assignee_name,
        yr,
        country_code,
        apps_in_country
    FROM (
        SELECT
            assignee_name,
            yr,
            country_code,
            apps_in_country,
            ROW_NUMBER() OVER (PARTITION BY assignee_name, yr
                               ORDER BY apps_in_country DESC NULLS LAST) AS rn
        FROM country_counts
    )
    WHERE rn = 1
)

/* 8. final result ---------------------------------------------------------*/
SELECT
    t.assignee_name                        AS "ASSIGNEE_NAME",
    t.total_apps                           AS "TOTAL_APPLICATIONS",
    b.yr                                   AS "YEAR_WITH_MAX_APPS",
    b.apps_in_year                         AS "APPS_IN_THAT_YEAR",
    c.country_code                         AS "TOP_COUNTRY_CODE_IN_YEAR"
FROM top3              t
JOIN best_year_pick    b ON b.assignee_name = t.assignee_name
JOIN best_country_pick c ON c.assignee_name = t.assignee_name
                         AND c.yr            = b.yr
ORDER BY t.total_apps DESC NULLS LAST;