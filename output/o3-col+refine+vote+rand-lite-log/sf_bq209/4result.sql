WITH cites AS (
    /* every (citing application → cited publication) pair */
    SELECT
        p2."application_number"                              AS "citing_app",
        p2."filing_date"                                     AS "citing_filing_date",
        f.value:"publication_number"::STRING                 AS "cited_pub_number"
    FROM PATENTS.PATENTS.PUBLICATIONS p2,
         LATERAL FLATTEN(input => p2."citation") f
),
granted_2010 AS (
    /* utility patents granted in calendar-year 2010 */
    SELECT
        p1."publication_number",
        p1."filing_date"
    FROM PATENTS.PATENTS.PUBLICATIONS p1
    WHERE p1."grant_date"       BETWEEN 20100101 AND 20101231
      AND p1."application_kind" = 'U'
)
SELECT COUNT(*) AS "num_utility_patents_2010_with_one_forward_citation_within_10y"
FROM (
    SELECT
        g."publication_number",
        COUNT(DISTINCT c."citing_app") AS "forward_cite_cnt"
    FROM granted_2010 g
    LEFT JOIN cites c
           ON c."cited_pub_number" = g."publication_number"
          /* only citations made within 10 years of the patent’s own filing date */
          AND DATEDIFF(
                  year,
                  TO_DATE(TO_CHAR(g."filing_date"), 'YYYYMMDD'),
                  TO_DATE(TO_CHAR(c."citing_filing_date"), 'YYYYMMDD')
              ) <= 10
    GROUP BY g."publication_number"
    HAVING COUNT(DISTINCT c."citing_app") = 1
);