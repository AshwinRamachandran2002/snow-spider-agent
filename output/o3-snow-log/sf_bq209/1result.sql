WITH target AS (      -- utility patents granted in calendar-year 2010
    SELECT
        "publication_number",
        "application_number",
        "filing_date"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "application_kind" = 'U'                     -- utility patent
      AND "grant_date" BETWEEN 20100101 AND 20101231
      AND "filing_date" IS NOT NULL
),

cit AS (               -- every patent-to-patent citation with citing filing-date
    SELECT
        p."application_number"                       AS citing_application_number,
        p."filing_date"                              AS citing_filing_date,
        c.value:"publication_number"::string         AS cited_publication_number
    FROM PATENTS.PATENTS.PUBLICATIONS  p,
         LATERAL FLATTEN (INPUT => p."citation")  c
    WHERE c.value:"publication_number" IS NOT NULL
      AND p."filing_date" IS NOT NULL
),

forward_cites AS (     -- citations that fall inside the 10-year window
    SELECT
        t."publication_number",
        COUNT(DISTINCT cit.citing_application_number) AS num_forward_cites
    FROM target t
    JOIN cit
      ON cit.cited_publication_number = t."publication_number"
     AND TO_DATE(cit.citing_filing_date::string,'YYYYMMDD')
         BETWEEN TO_DATE(t."filing_date"::string,'YYYYMMDD')
             AND DATEADD(year,10,TO_DATE(t."filing_date"::string,'YYYYMMDD'))
    GROUP BY t."publication_number"
    HAVING num_forward_cites = 1                     -- exactly one forward citation
)

SELECT COUNT(*) AS "NUM_UTILITY_PATENTS_WITH_EXACTLY_ONE_FORWARD_CITATION"
FROM forward_cites;