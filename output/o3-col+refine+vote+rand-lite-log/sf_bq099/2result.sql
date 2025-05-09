WITH a01b3 AS (   -- every A01B3 application split out by assignee
    SELECT
        ah.value:"name"::STRING                              AS "assignee_name",
        YEAR(TO_DATE("publication_date"::STRING,'YYYYMMDD')) AS "pub_year",
        "country_code"
    FROM PATENTS.PATENTS.PUBLICATIONS
         ,LATERAL FLATTEN(input => "cpc")                   c
         ,LATERAL FLATTEN(input => "assignee_harmonized")   ah
    WHERE c.value:"code"::STRING ILIKE 'A01B3%'
),

/* -------- top-3 assignees by total A01B3 applications -------- */
top3 AS (
    SELECT
        "assignee_name",
        COUNT(*) AS "total_apps"
    FROM a01b3
    GROUP BY "assignee_name"
    ORDER BY "total_apps" DESC NULLS LAST
    LIMIT 3
),

/* -------- determine the peak publication year for each top assignee -------- */
year_counts AS (
    SELECT
        a."assignee_name",
        a."pub_year",
        COUNT(*) AS "apps_in_year"
    FROM a01b3 a
    JOIN top3  t ON a."assignee_name" = t."assignee_name"
    GROUP BY a."assignee_name", a."pub_year"
),
peak_year AS (
    SELECT *
    FROM (
        SELECT
            "assignee_name",
            "pub_year",
            "apps_in_year",
            ROW_NUMBER() OVER (PARTITION BY "assignee_name"
                               ORDER BY "apps_in_year" DESC, "pub_year") AS rn
        FROM year_counts
    )
    WHERE rn = 1
),

/* -------- leading country (most apps) within that peak year --- */
country_counts AS (
    SELECT
        a."assignee_name",
        a."pub_year",
        a."country_code",
        COUNT(*) AS "apps_in_country"
    FROM a01b3 a
    JOIN peak_year p
      ON p."assignee_name" = a."assignee_name"
     AND p."pub_year"      = a."pub_year"
    GROUP BY a."assignee_name", a."pub_year", a."country_code"
),
top_country AS (
    SELECT *
    FROM (
        SELECT
            "assignee_name",
            "pub_year",
            "country_code",
            "apps_in_country",
            ROW_NUMBER() OVER (PARTITION BY "assignee_name", "pub_year"
                               ORDER BY "apps_in_country" DESC, "country_code") AS rn
        FROM country_counts
    )
    WHERE rn = 1
)

/* ------------------- final result ----------------------------- */
SELECT
       t."assignee_name",
       t."total_apps",
       p."pub_year"       AS "peak_year",
       p."apps_in_year"   AS "apps_in_peak_year",
       c."country_code"   AS "top_country_in_peak_year"
FROM top3        t
JOIN peak_year   p ON p."assignee_name" = t."assignee_name"
JOIN top_country c ON c."assignee_name" = t."assignee_name"
                  AND c."pub_year"      = p."pub_year"
ORDER BY t."total_apps" DESC NULLS LAST;