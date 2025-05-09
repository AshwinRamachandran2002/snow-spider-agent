WITH filtered AS (   -- all publications whose CPC starts with 'A61'
    SELECT
        p."publication_number",
        p."country_code",
        p."publication_date",
        ass.value:"name"::string                               AS assignee_name
    FROM PATENTS.PATENTS.PUBLICATIONS            p,
         LATERAL FLATTEN(INPUT => p."cpc")       c,
         LATERAL FLATTEN(INPUT => p."assignee_harmonized") ass
    WHERE c.value:"code"::string LIKE 'A61%'
),                                                           -- assignee with most A61 publications
assignee_totals AS (
    SELECT assignee_name,
           COUNT(DISTINCT "publication_number")              AS total_pubs
    FROM filtered
    GROUP BY assignee_name
),
top_assignee AS (
    SELECT assignee_name
    FROM assignee_totals
    ORDER BY total_pubs DESC NULLS LAST, assignee_name
    LIMIT 1
),                                                           -- busiest year for that assignee
assignee_yearly AS (
    SELECT
        assignee_name,
        FLOOR("publication_date" / 10000)                    AS pub_year,
        COUNT(DISTINCT "publication_number")                 AS year_pubs
    FROM filtered
    WHERE assignee_name IN (SELECT assignee_name FROM top_assignee)
    GROUP BY assignee_name, pub_year
),
busiest_year AS (
    SELECT assignee_name, pub_year
    FROM (
        SELECT *,
               ROW_NUMBER() OVER (PARTITION BY assignee_name
                                  ORDER BY year_pubs DESC NULLS LAST, pub_year) AS rn
        FROM assignee_yearly
    )
    WHERE rn = 1
),                                                           -- country counts in that busiest year
country_counts AS (
    SELECT
        f."country_code",
        COUNT(DISTINCT f."publication_number")               AS cnt
    FROM filtered f
    JOIN busiest_year b
          ON f.assignee_name            = b.assignee_name
         AND FLOOR(f."publication_date" / 10000) = b.pub_year
    GROUP BY f."country_code"
),                                                           -- top‑5 jurisdictions
top_countries AS (
    SELECT "country_code", cnt
    FROM (
        SELECT
            "country_code",
            cnt,
            ROW_NUMBER() OVER (ORDER BY cnt DESC NULLS LAST, "country_code") AS rn
        FROM country_counts
    )
    WHERE rn <= 5
)
SELECT LISTAGG("country_code", ',') 
       WITHIN GROUP (ORDER BY cnt DESC, "country_code")      AS "TOP_JURISDICTIONS"
FROM top_countries;