SELECT COUNT(*) AS "number_of_patents_with_exactly_one_forward_citation"
FROM (
    SELECT P."publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS P
    INNER JOIN (
        SELECT c.value:"publication_number"::STRING AS "cited_publication_number",
               TO_DATE(NULLIF(Q."filing_date", 0)::VARCHAR, 'YYYYMMDD') AS "citing_filing_date"
        FROM PATENTS.PATENTS.PUBLICATIONS Q,
             LATERAL FLATTEN(input => Q."citation") c
        WHERE c.value:"publication_number"::STRING IS NOT NULL
          AND Q."filing_date" > 0
    ) citations ON citations."cited_publication_number" = P."publication_number"
                 AND citations."citing_filing_date" BETWEEN TO_DATE(NULLIF(P."filing_date", 0)::VARCHAR, 'YYYYMMDD')
                                                   AND DATEADD(year, 10, TO_DATE(NULLIF(P."filing_date", 0)::VARCHAR, 'YYYYMMDD'))
    WHERE P."application_kind" = 'U'
      AND TO_DATE(NULLIF(P."grant_date", 0)::VARCHAR, 'YYYYMMDD') BETWEEN '2010-01-01' AND '2010-12-31'
      AND P."filing_date" > 0
    GROUP BY P."publication_number"
    HAVING COUNT(*) = 1
) AS sub;