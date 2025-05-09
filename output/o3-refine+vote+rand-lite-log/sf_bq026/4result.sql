WITH cpc_a61 AS (   -- publications that have at least one CPC symbol starting with A61
    SELECT DISTINCT
        p."publication_number",
        p."country_code",
        p."publication_date",
        TO_NUMBER(SUBSTRING(p."publication_date"::STRING, 1, 4)) AS pub_year,
        ah.value:"name"::STRING                                   AS assignee_name
    FROM PATENTS.PATENTS.PUBLICATIONS AS p
         ,LATERAL FLATTEN(input => p."cpc")                 AS cpc_flat
         ,LATERAL FLATTEN(input => p."assignee_harmonized") AS ah
    WHERE cpc_flat.value:"code"::STRING LIKE 'A61%'        -- keep only A61 CPC codes
      AND ah.value:"name" IS NOT NULL                      -- valid assignee names
), most_active_assignee AS (     -- assignee with the highest number of A61‑class patents
    SELECT assignee_name
    FROM cpc_a61
    GROUP BY assignee_name
    ORDER BY COUNT(*) DESC NULLS LAST
    LIMIT 1
), busiest_year AS (             -- that assignee’s busiest publication year
    SELECT pub_year
    FROM cpc_a61
    WHERE assignee_name = (SELECT assignee_name FROM most_active_assignee)
    GROUP BY pub_year
    ORDER BY COUNT(*) DESC NULLS LAST, pub_year
    LIMIT 1
)
SELECT LISTAGG(t."country_code", ',')
         WITHIN GROUP (ORDER BY t.patent_count DESC, t."country_code") AS top_jurisdictions
FROM (
    SELECT
        "country_code",
        COUNT(*) AS patent_count
    FROM cpc_a61
    WHERE assignee_name = (SELECT assignee_name FROM most_active_assignee)
      AND pub_year      = (SELECT pub_year FROM busiest_year)
    GROUP BY "country_code"
    ORDER BY patent_count DESC NULLS LAST, "country_code"
    LIMIT 5
) AS t;