WITH target_patents AS (                -- utility patents granted in 2010
    SELECT
        "publication_number",
        "application_number",
        TRY_TO_DATE("filing_date"::VARCHAR , 'YYYYMMDD') AS filing_dt
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "application_kind" = 'A'                          -- utility patents
      AND "grant_date" BETWEEN 20100101 AND 20101231        -- granted in 2010
      AND TRY_TO_DATE("filing_date"::VARCHAR , 'YYYYMMDD') IS NOT NULL
),                                                          -- -----------------------
citations AS (                   -- every citation with citing patent’s filing date
    SELECT
        p."application_number"                              AS citing_app_no,
        TRY_TO_DATE(p."filing_date"::VARCHAR , 'YYYYMMDD')  AS citing_filing_dt,
        UPPER(c.value:"publication_number"::STRING)         AS cited_pub_no,
        UPPER(c.value:"application_number"::STRING)         AS cited_app_no
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(INPUT => p."citation") c
    WHERE c.value IS NOT NULL
      AND TRY_TO_DATE(p."filing_date"::VARCHAR , 'YYYYMMDD') IS NOT NULL
),                                                          -- -----------------------
forward_counts AS (        -- forward citations within 10-year window after filing
    SELECT
        t."publication_number",
        COUNT(DISTINCT c.citing_app_no) AS fwd_cite_cnt
    FROM target_patents t
    LEFT JOIN citations c
           ON (c.cited_pub_no = UPPER(t."publication_number")
            OR c.cited_app_no = UPPER(t."application_number"))
          AND c.citing_filing_dt >= t.filing_dt
          AND c.citing_filing_dt < DATEADD(year, 10, t.filing_dt)
    GROUP BY t."publication_number"
),                                                          -- -----------------------
one_citation_patents AS (
    SELECT "publication_number"
    FROM   forward_counts
    WHERE  fwd_cite_cnt = 1                                  -- exactly one forward citation
)
SELECT COUNT(*) AS num_utility_patents_granted_2010_with_one_fwd_citation
FROM   one_citation_patents;