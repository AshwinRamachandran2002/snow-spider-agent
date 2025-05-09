WITH assignee_pubs AS (   -- every A61 publication split out by individual assignee
    SELECT
        UPPER(ah.value:"name"::string)            AS "ASSIGNEE_NAME",
        p."publication_number"                   AS "PUB_NR",
        FLOOR(p."publication_date"/10000)        AS "PUB_YEAR",
        p."country_code"                         AS "COUNTRY_CODE"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN (INPUT => p."cpc")      c,   -- explode CPC codes
         LATERAL FLATTEN (INPUT => p."assignee_harmonized") ah  -- explode assignees
    WHERE STARTSWITH(c.value:"code"::string,'A61')      -- keep only A61 category
          AND p."publication_number" IS NOT NULL
),

top_assignee AS (        -- assignee with the most A61 publications overall
    SELECT "ASSIGNEE_NAME"
    FROM (
        SELECT "ASSIGNEE_NAME",
               COUNT(DISTINCT "PUB_NR") AS cnt
        FROM assignee_pubs
        GROUP BY "ASSIGNEE_NAME"
    )
    ORDER BY cnt DESC NULLS LAST, "ASSIGNEE_NAME"
    LIMIT 1
),

busiest_year AS (        -- that assignee’s busiest publication year
    SELECT "PUB_YEAR"
    FROM (
        SELECT "PUB_YEAR",
               COUNT(DISTINCT "PUB_NR") AS cnt
        FROM assignee_pubs
        WHERE "ASSIGNEE_NAME" = (SELECT "ASSIGNEE_NAME" FROM top_assignee)
        GROUP BY "PUB_YEAR"
    )
    ORDER BY cnt DESC NULLS LAST, "PUB_YEAR"
    LIMIT 1
)

SELECT LISTAGG("COUNTRY_CODE", ',')
         WITHIN GROUP (ORDER BY cnt DESC, "COUNTRY_CODE")  AS "TOP_FIVE_JURISDICTIONS"
FROM (
    SELECT "COUNTRY_CODE",
           COUNT(DISTINCT "PUB_NR") AS cnt
    FROM assignee_pubs
    WHERE "ASSIGNEE_NAME" = (SELECT "ASSIGNEE_NAME" FROM top_assignee)
      AND "PUB_YEAR"       = (SELECT "PUB_YEAR"       FROM busiest_year)
    GROUP BY "COUNTRY_CODE"
    ORDER BY cnt DESC NULLS LAST, "COUNTRY_CODE"
    LIMIT 5
);