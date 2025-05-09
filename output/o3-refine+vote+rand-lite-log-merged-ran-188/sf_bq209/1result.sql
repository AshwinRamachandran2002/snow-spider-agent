WITH target_patents AS (   -- utility patents granted in 2010
    SELECT
        "publication_number",
        "application_number",
        "filing_date",
        TO_DATE(LPAD("filing_date"::STRING,8,'0'),'YYYYMMDD')           AS filing_dt,
        DATEADD(year,10,TO_DATE(LPAD("filing_date"::STRING,8,'0'),'YYYYMMDD')) AS cutoff_dt
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "application_kind" = 'A'                              -- utility (standard) patents
      AND "grant_date" BETWEEN 20100101 AND 20101231            -- granted in 2010
),

citation_links AS (          -- every (citing → cited) relation in the DB
    SELECT
        p."application_number"                                  AS citing_app,
        p."filing_date"                                         AS citing_filing_date,
        TO_DATE(LPAD(p."filing_date"::STRING,8,'0'),'YYYYMMDD') AS citing_filing_dt,
        f.value:"publication_number"::STRING                    AS cited_pub
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."citation") f
    WHERE f.value:"publication_number" IS NOT NULL
),

forward_citations AS (       -- keep only citations that fall in the 10‑year window
    SELECT
        t."publication_number",
        c.citing_app
    FROM target_patents t
    JOIN citation_links  c
          ON  c.cited_pub = t."publication_number"
         AND c.citing_filing_dt <= t.cutoff_dt                  -- within 10 years after filing
)

SELECT COUNT(*) AS patents_with_exactly_one_forward_citation
FROM (
    SELECT
        "publication_number"
    FROM forward_citations
    GROUP BY "publication_number"
    HAVING COUNT(DISTINCT citing_app) = 1                       -- exactly one distinct forward citation
) ;