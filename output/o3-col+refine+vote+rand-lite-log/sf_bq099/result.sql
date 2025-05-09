/*  Top-3 assignee statistics for CPC class A01B3%  */
WITH filtered AS (      -- one row per (publication, assignee) that has at least one A01B3* CPC code
    SELECT DISTINCT
           p."publication_number",
           p."country_code",
           p."filing_date",
           a.value::VARIANT:"name"::STRING  AS "assignee_name"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc")               c,
         LATERAL FLATTEN(input => p."assignee_harmonized") a
    WHERE c.value::VARIANT:"code"::STRING ILIKE 'A01B3%'
      AND a.value::VARIANT:"name" IS NOT NULL
      AND p."filing_date" IS NOT NULL
      AND p."filing_date" > 0
),
/* total application count for every assignee */
top_assignees AS (
    SELECT "assignee_name",
           COUNT(*)                       AS "total_apps"
    FROM filtered
    GROUP BY "assignee_name"
    ORDER BY "total_apps" DESC NULLS LAST
    LIMIT 3
),
/* yearly application counts for the top-3 assignees */
yearly AS (
    SELECT f."assignee_name",
           (f."filing_date"/10000)::INT   AS "year",
           COUNT(*)                       AS "year_apps"
    FROM filtered f
    JOIN top_assignees t
      ON f."assignee_name" = t."assignee_name"
    GROUP BY f."assignee_name",
             (f."filing_date"/10000)::INT
),
/* pick the peak year for each assignee */
assignee_peak_year AS (
    SELECT y."assignee_name",
           y."year"               AS "peak_year",
           y."year_apps",
           ROW_NUMBER() OVER (PARTITION BY y."assignee_name"
                              ORDER BY y."year_apps" DESC NULLS LAST,
                                       y."year"       ASC) AS rn
    FROM yearly y
),
peak_year AS (              -- keep only the best row per assignee
    SELECT *
    FROM assignee_peak_year
    WHERE rn = 1
),
/* within each (assignee, peak year) find the country code with most applications */
country_rank AS (
    SELECT f."assignee_name",
           (f."filing_date"/10000)::INT      AS "year",
           f."country_code",
           COUNT(*)                          AS "cc_apps",
           ROW_NUMBER() OVER (PARTITION BY f."assignee_name",
                                            (f."filing_date"/10000)::INT
                               ORDER BY COUNT(*) DESC NULLS LAST,
                                        f."country_code" ASC) AS cc_rn
    FROM filtered f
    JOIN peak_year py
      ON f."assignee_name" = py."assignee_name"
     AND (f."filing_date"/10000)::INT = py."peak_year"
    GROUP BY f."assignee_name",
             (f."filing_date"/10000)::INT,
             f."country_code"
),
peak_country AS (
    SELECT "assignee_name",
           "year" AS "peak_year",
           "country_code"
    FROM country_rank
    WHERE cc_rn = 1
)

/* final result */
SELECT ta."assignee_name",
       ta."total_apps"                       AS "total_number_of_applications",
       py."peak_year"                        AS "year_with_most_applications",
       py."year_apps"                        AS "applications_in_that_year",
       pc."country_code"                     AS "top_country_code_in_peak_year"
FROM top_assignees    ta
JOIN peak_year        py ON py."assignee_name" = ta."assignee_name"
JOIN peak_country     pc ON pc."assignee_name" = ta."assignee_name"
                        AND pc."peak_year"     = py."peak_year"
ORDER BY ta."total_apps" DESC NULLS LAST;