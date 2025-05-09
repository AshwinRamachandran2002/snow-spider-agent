WITH d AS (   -- one row per (publication, assignee) that has CPC starting with A01B3
    SELECT DISTINCT
           p."publication_number",
           p."filing_date",
           p."country_code",
           ah.value:"name"::string AS assignee_name
    FROM PATENTS.PATENTS.PUBLICATIONS            AS p,
         LATERAL FLATTEN(input => p."cpc")       AS cpc_item,
         LATERAL FLATTEN(input => p."assignee_harmonized") AS ah
    WHERE cpc_item.value:"code"::string LIKE 'A01B3%'   -- class A01B3
      AND p."filing_date" IS NOT NULL
),

/* total applications per assignee */
assignee_totals AS (
    SELECT assignee_name,
           COUNT(*) AS total_apps
    FROM d
    GROUP BY assignee_name
),

/* keep only the overall Top–3 assignees */
top_assignees AS (
    SELECT assignee_name
    FROM assignee_totals
    ORDER BY total_apps DESC NULLS LAST
    LIMIT 3
),

d_top AS (      -- data restricted to the 3 leading assignees
    SELECT *
    FROM d
    WHERE assignee_name IN (SELECT assignee_name FROM top_assignees)
),

/* yearly application counts */
year_counts AS (
    SELECT assignee_name,
           FLOOR("filing_date"/10000) AS yr,
           COUNT(*)                  AS apps_in_year
    FROM d_top
    GROUP BY assignee_name, yr
),

/* pick the peak-year per assignee */
peak_year AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY assignee_name 
                              ORDER BY apps_in_year DESC NULLS LAST, yr) AS rn
    FROM year_counts
),
peak AS (
    SELECT assignee_name,
           yr              AS peak_year,
           apps_in_year
    FROM peak_year
    WHERE rn = 1
),

/* country distribution inside each peak-year */
country_counts AS (
    SELECT assignee_name,
           FLOOR("filing_date"/10000) AS yr,
           "country_code",
           COUNT(*)                  AS cnt
    FROM d_top
    GROUP BY assignee_name, yr, "country_code"
),
country_in_peak AS (
    SELECT c.assignee_name,
           c."country_code",
           ROW_NUMBER() OVER (PARTITION BY c.assignee_name 
                              ORDER BY c.cnt DESC NULLS LAST, c."country_code") AS rn
    FROM country_counts  AS c
    JOIN peak            AS p
      ON p.assignee_name = c.assignee_name
     AND p.peak_year     = c.yr
),

/* assemble final answer */
final AS (
    SELECT p.assignee_name,
           t.total_apps                        AS total_applications,
           p.peak_year                         AS year_most_apps,
           p.apps_in_year                      AS num_apps_that_year,
           c."country_code"                    AS top_country_code
    FROM peak              AS p
    JOIN assignee_totals   AS t ON t.assignee_name = p.assignee_name
    JOIN country_in_peak   AS c ON c.assignee_name = p.assignee_name
    WHERE c.rn = 1
)

SELECT *
FROM final
ORDER BY total_applications DESC NULLS LAST;