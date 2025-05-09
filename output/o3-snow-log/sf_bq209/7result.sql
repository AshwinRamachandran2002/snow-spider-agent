WITH target_patents AS (      -- utility patents granted in 2010
    SELECT
        p."publication_number"          AS orig_pub_num,
        p."application_number"          AS orig_app_num,
        p."filing_date"                 AS orig_filing_date
    FROM PATENTS.PATENTS.PUBLICATIONS p
    WHERE p."grant_date" BETWEEN 20100101 AND 20101231   -- granted in 2010
      AND p."application_kind" = 'U'                     -- utility patents
      AND p."filing_date" IS NOT NULL                    -- need filing date
),
forward_citations AS (        -- explode all citations in every publication
    SELECT
        citing."application_number"                      AS citing_app_num,
        citing."filing_date"                             AS citing_filing_date,
        cited.value:"publication_number"::STRING         AS cited_pub_num
    FROM PATENTS.PATENTS.PUBLICATIONS  citing,
         LATERAL FLATTEN(INPUT => citing."citation") cited
    WHERE citing."filing_date" IS NOT NULL
      AND citing."application_number" IS NOT NULL
),
citations_within_10yrs AS (   -- keep only citations within 10-yr window
    SELECT
        t.orig_pub_num,
        fc.citing_app_num
    FROM target_patents t
    JOIN forward_citations fc
          ON fc.cited_pub_num = t.orig_pub_num
    WHERE DATEDIFF(
              year,
              TO_DATE(t.orig_filing_date::STRING,'YYYYMMDD'),
              TO_DATE(fc.citing_filing_date::STRING,'YYYYMMDD')
          ) <= 10               -- within 10 years after original filing
),
citation_counts AS (          -- count distinct citing apps per patent
    SELECT
        orig_pub_num,
        COUNT(DISTINCT citing_app_num) AS num_forward_cites
    FROM citations_within_10yrs
    GROUP BY orig_pub_num
)
-- final answer: how many patents have exactly one such forward citation
SELECT COUNT(*) AS num_utility_patents_granted_2010_with_exactly_one_forward_citation
FROM citation_counts
WHERE num_forward_cites = 1;