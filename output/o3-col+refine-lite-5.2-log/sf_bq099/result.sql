WITH a01b3_apps AS (          -- every application that carries at least one CPC starting with 'A01B3'
    SELECT
        p."application_number",
        p."country_code",
        (p."filing_date"/10000)::INT              AS "year",
        a.value::VARIANT:"name"::STRING           AS "assignee_name"
    FROM PATENTS.PATENTS.PUBLICATIONS  p
         ,LATERAL FLATTEN(input => p."cpc")                 c
         ,LATERAL FLATTEN(input => p."assignee_harmonized") a
    WHERE c.value::VARIANT:"code"::STRING ILIKE 'A01B3%'
),

assignee_totals AS (          -- total applications per assignee, keep TOP‑3
    SELECT
        "assignee_name",
        COUNT(DISTINCT "application_number")      AS "total_apps"
    FROM a01b3_apps
    GROUP BY "assignee_name"
    ORDER BY "total_apps" DESC NULLS LAST
    LIMIT 3
),

year_counts AS (              -- yearly application counts for those TOP‑3 assignees
    SELECT
        a."assignee_name",
        a."year",
        COUNT(DISTINCT a."application_number")    AS "apps_in_year",
        ROW_NUMBER() OVER (PARTITION BY a."assignee_name"
                           ORDER BY COUNT(DISTINCT a."application_number") DESC,
                                    a."year")     AS rn
    FROM a01b3_apps a
    JOIN assignee_totals t
         ON a."assignee_name" = t."assignee_name"
    GROUP BY a."assignee_name", a."year"
),

top_year AS (                 -- the single year with the most applications for each assignee
    SELECT *
    FROM year_counts
    WHERE rn = 1
),

country_counts AS (           -- within that peak year: which country code appears most
    SELECT
        a."assignee_name",
        a."year",
        a."country_code",
        COUNT(DISTINCT a."application_number")    AS "apps_in_country",
        ROW_NUMBER() OVER (PARTITION BY a."assignee_name", a."year"
                           ORDER BY COUNT(DISTINCT a."application_number") DESC,
                                    a."country_code")       AS rn
    FROM a01b3_apps a
    JOIN top_year y
         ON a."assignee_name" = y."assignee_name"
        AND a."year"          = y."year"
    GROUP BY a."assignee_name", a."year", a."country_code"
)

SELECT
    y."assignee_name"                          AS "assignee",
    t."total_apps",
    y."year"                                   AS "peak_year",
    y."apps_in_year",
    c."country_code"                           AS "top_country_code"
FROM top_year          y
JOIN assignee_totals   t  ON y."assignee_name" = t."assignee_name"
JOIN country_counts    c  ON c."assignee_name" = y."assignee_name"
                         AND c."year"          = y."year"
WHERE c.rn = 1
ORDER BY t."total_apps" DESC NULLS LAST,
         "assignee";