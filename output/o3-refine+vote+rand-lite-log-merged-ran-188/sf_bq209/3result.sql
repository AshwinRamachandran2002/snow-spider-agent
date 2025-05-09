WITH granted_2010 AS (
    /* Utility patents (application_kind = 'A' or 'U') that were granted in 2010 */
    SELECT
        "publication_number",
        "application_number",
        TO_DATE("filing_date"::STRING , 'YYYYMMDD') AS filing_date
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "grant_date" BETWEEN 20100101 AND 20101231              -- granted in 2010
      AND "application_kind" IN ('A','U')                         -- utility‑type patents
      AND "filing_date" IS NOT NULL
),
all_citations AS (
    /* Flatten every citation listed in every publication */
    SELECT
        p2."application_number"                                   AS citing_application,
        TO_DATE(p2."filing_date"::STRING , 'YYYYMMDD')            AS citing_filing_date,
        cited.value:"publication_number"::STRING                  AS cited_publication
    FROM PATENTS.PATENTS.PUBLICATIONS p2,
         LATERAL FLATTEN(input => p2."citation") cited
    WHERE p2."filing_date" IS NOT NULL
),
forward_cite_count AS (
    /* Forward citations within 10‑year window following the cited patent’s filing date */
    SELECT
        g."publication_number",
        COUNT(DISTINCT a.citing_application) AS forward_citations
    FROM granted_2010 g
    JOIN all_citations a
      ON a.cited_publication = g."publication_number"
     AND a.citing_filing_date >  g.filing_date                       -- after the cited patent filed
     AND a.citing_filing_date <= DATEADD(year, 10, g.filing_date)    -- within 10 years
    GROUP BY g."publication_number"
    HAVING COUNT(DISTINCT a.citing_application) = 1                  -- exactly one forward citation
)
SELECT COUNT(*) AS "utility_patents_granted_2010_with_exactly_one_forward_citation_in_10yrs"
FROM forward_cite_count;