WITH "PUBS_A61" AS (
    SELECT DISTINCT
           P."publication_number",
           P."country_code",
           TO_NUMBER(LEFT(P."publication_date", 4))                    AS "pub_year",
           TRIM(UPPER(AH.VALUE:NAME::STRING))                          AS "assignee_name"
    FROM   PATENTS.PATENTS.PUBLICATIONS  P,
           LATERAL FLATTEN(INPUT => P."cpc")                C,
           LATERAL FLATTEN(INPUT => P."assignee_harmonized") AH
    WHERE  C.VALUE:code::STRING LIKE 'A61%'          -- CPC category A61
      AND  AH.VALUE:NAME IS NOT NULL
),
"ASSIGNEE_COUNTS" AS (
    SELECT "assignee_name",
           COUNT(DISTINCT "publication_number") AS "num_pubs"
    FROM   "PUBS_A61"
    GROUP  BY "assignee_name"
),
"TOP_ASSIGNEE" AS (      -- the single most‑active assignee in A61
    SELECT "assignee_name"
    FROM   "ASSIGNEE_COUNTS"
    ORDER  BY "num_pubs" DESC NULLS LAST, "assignee_name"
    LIMIT  1
),
"ASSIGNEE_YEAR_COUNTS" AS (   -- yearly activity for that assignee
    SELECT "pub_year",
           COUNT(DISTINCT "publication_number") AS "num_pubs"
    FROM   "PUBS_A61"
    WHERE  "assignee_name" = (SELECT "assignee_name" FROM "TOP_ASSIGNEE")
    GROUP  BY "pub_year"
),
"BUSIEST_YEAR" AS (      -- busiest year for that assignee
    SELECT "pub_year"
    FROM   "ASSIGNEE_YEAR_COUNTS"
    ORDER  BY "num_pubs" DESC NULLS LAST, "pub_year"
    LIMIT  1
),
"JURISDICTION_COUNTS" AS (  -- top 5 jurisdictions in that year
    SELECT "country_code",
           COUNT(DISTINCT "publication_number") AS "num_pubs"
    FROM   "PUBS_A61"
    WHERE  "assignee_name" = (SELECT "assignee_name" FROM "TOP_ASSIGNEE")
      AND  "pub_year"      = (SELECT "pub_year"      FROM "BUSIEST_YEAR")
    GROUP  BY "country_code"
    ORDER  BY "num_pubs" DESC NULLS LAST, "country_code"
    LIMIT  5
)
SELECT LISTAGG("country_code", ',') 
         WITHIN GROUP (ORDER BY "num_pubs" DESC, "country_code") 
         AS "top_5_jurisdictions"
FROM   "JURISDICTION_COUNTS";