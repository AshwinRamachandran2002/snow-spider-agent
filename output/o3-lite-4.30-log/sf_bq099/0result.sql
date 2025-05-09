WITH a01b_applications AS (
    SELECT
        p."publication_number"                              AS publication_number,
        (p."publication_date" / 10000)::INT                 AS pub_year,
        p."country_code"                                    AS country_code,
        TRIM(ah.value:"name"::STRING)                       AS assignee_name
    FROM PATENTS.PATENTS."PUBLICATIONS" p,
         LATERAL FLATTEN(input => p."cpc") f,
         LATERAL FLATTEN(input => p."assignee_harmonized") ah
    WHERE f.value:"code"::STRING LIKE 'A01B3%'
      AND TRIM(ah.value:"name"::STRING) IS NOT NULL
      AND TRIM(ah.value:"name"::STRING) <> ''
),
top_assignees AS (
    SELECT
        assignee_name,
        COUNT(DISTINCT publication_number) AS total_apps
    FROM a01b_applications
    GROUP BY assignee_name
    ORDER BY total_apps DESC NULLS LAST, assignee_name
    LIMIT 3
),
assignee_year_counts AS (
    SELECT
        a.assignee_name,
        a.pub_year,
        COUNT(DISTINCT a.publication_number) AS apps_in_year,
        ROW_NUMBER() OVER (
            PARTITION BY a.assignee_name
            ORDER BY COUNT(DISTINCT a.publication_number) DESC, a.pub_year
        ) AS rn
    FROM a01b_applications a
    JOIN top_assignees t ON a.assignee_name = t.assignee_name
    GROUP BY a.assignee_name, a.pub_year
),
peak_year AS (
    SELECT
        assignee_name,
        pub_year AS peak_year,
        apps_in_year
    FROM assignee_year_counts
    WHERE rn = 1
),
country_counts_in_peak_year AS (
    SELECT
        a.assignee_name,
        a.pub_year,
        a.country_code,
        COUNT(DISTINCT a.publication_number) AS apps_in_country,
        ROW_NUMBER() OVER (
            PARTITION BY a.assignee_name, a.pub_year
            ORDER BY COUNT(DISTINCT a.publication_number) DESC, a.country_code
        ) AS rn
    FROM a01b_applications a
    JOIN peak_year p
      ON a.assignee_name = p.assignee_name
     AND a.pub_year      = p.peak_year
    GROUP BY a.assignee_name, a.pub_year, a.country_code
)
SELECT
    p.assignee_name                                   AS assignee,
    t.total_apps                                      AS total_applications,
    p.peak_year,
    p.apps_in_year                                    AS applications_in_peak_year,
    c.country_code                                    AS country_code_in_peak_year
FROM peak_year p
JOIN top_assignees              t ON p.assignee_name = t.assignee_name
JOIN country_counts_in_peak_year c ON p.assignee_name = c.assignee_name
                                   AND p.peak_year   = c.pub_year
                                   AND c.rn = 1
ORDER BY t.total_apps DESC NULLS LAST, p.assignee_name;