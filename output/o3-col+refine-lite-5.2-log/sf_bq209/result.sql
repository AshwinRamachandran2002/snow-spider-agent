/* Count 2010‑granted utility patents that have exactly
   ONE forward citation within 10 years of their own filing date */
WITH target AS (                     -- 2010 grants, utility patents, valid filing date
    SELECT  "publication_number"                                  AS "target_pub",
            "application_number"                                  AS "target_app",
            TO_DATE(TO_VARCHAR(NULLIF("filing_date",0)),'YYYYMMDD') 
                                                                   AS "target_filing"
    FROM    PATENTS.PATENTS.PUBLICATIONS
    WHERE   "grant_date" BETWEEN 20100101 AND 20101231
      AND   "application_kind" = 'A'
      AND   NULLIF("filing_date",0) IS NOT NULL                   -- exclude unknown dates
),
cit AS (                        -- flattened citing‑cited relationships
    SELECT  p."application_number"                                AS "citing_app",
            TO_DATE(TO_VARCHAR(NULLIF(p."filing_date",0)),'YYYYMMDD') 
                                                                   AS "citing_filing",
            f.value:"publication_number"::STRING                  AS "cited_pub"
    FROM    PATENTS.PATENTS.PUBLICATIONS p,
            LATERAL FLATTEN(input => p."citation") f
    WHERE   p."citation" IS NOT NULL
      AND   p."citation" <> '[]'
      AND   f.value:"publication_number" IS NOT NULL
),
agg AS (                       -- count distinct citing apps within 10‑yr window
    SELECT  t."target_pub",
            COUNT(DISTINCT c."citing_app")        AS "fwd_cnt"
    FROM    target t
    LEFT JOIN cit c
           ON c."cited_pub" = t."target_pub"
          AND c."citing_filing" IS NOT NULL
          AND c."citing_filing" 
              <= DATEADD(year, 10, t."target_filing")
    GROUP BY t."target_pub"
)
SELECT COUNT(*) AS "utility_patents_granted_2010_with_one_forward_citation"
FROM   agg
WHERE  "fwd_cnt" = 1;