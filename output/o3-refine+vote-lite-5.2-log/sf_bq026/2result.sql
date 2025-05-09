WITH A61_PUBS AS (   -- publications that carry at least one CPC code starting with 'A61'
    SELECT DISTINCT p."publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."cpc") c
    WHERE c.value:"code"::string LIKE 'A61%'
),                                                         
ASSIGNEE_PUBS AS (   -- explode assignees for those publications, keep usable filing dates
    SELECT  p."publication_number",
            p."country_code",
            p."filing_date",
            FLOOR(p."filing_date"/10000)              AS filing_year,   -- derive year without date parsing
            a.value:"name"::string                    AS assignee_name
    FROM PATENTS.PATENTS.PUBLICATIONS p
    JOIN A61_PUBS ap
      ON ap."publication_number" = p."publication_number",
         LATERAL FLATTEN(input => p."assignee_harmonized") a
    WHERE p."filing_date" BETWEEN 19000101 AND 20991231    -- exclude missing / 0 values safely
      AND a.value:"name" IS NOT NULL
),                                                         
TOP_ASSIGNEE AS (   -- the most active assignee in A61
    SELECT assignee_name
    FROM ASSIGNEE_PUBS
    GROUP BY assignee_name
    ORDER BY COUNT(DISTINCT "publication_number") DESC NULLS LAST,
             assignee_name
    LIMIT 1
),                                                         
BUSIEST_YEAR AS (   -- that assignee's busiest filing year
    SELECT filing_year
    FROM ASSIGNEE_PUBS
    WHERE assignee_name = (SELECT assignee_name FROM TOP_ASSIGNEE)
    GROUP BY filing_year
    ORDER BY COUNT(DISTINCT "publication_number") DESC NULLS LAST,
             filing_year
    LIMIT 1
),                                                         
TOP_JURISDICTIONS AS (   -- top‑5 jurisdictions in that busiest year
    SELECT "country_code",
           COUNT(DISTINCT "publication_number") AS cnt
    FROM ASSIGNEE_PUBS
    WHERE assignee_name = (SELECT assignee_name FROM TOP_ASSIGNEE)
      AND filing_year    = (SELECT filing_year FROM BUSIEST_YEAR)
    GROUP BY "country_code"
    ORDER BY cnt DESC NULLS LAST,
             "country_code"
    LIMIT 5
)
SELECT LISTAGG("country_code", ',') 
       WITHIN GROUP (ORDER BY cnt DESC NULLS LAST, "country_code")  AS "top_jurisdictions"
FROM TOP_JURISDICTIONS;