WITH granted_2010 AS (   /* utility patents granted in calendar‑year 2010 */
    SELECT
        "publication_number",
        "application_number",
        TRY_TO_DATE(TO_VARCHAR("filing_date"),'YYYYMMDD') AS filing_dt
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "application_kind" = 'A'                          -- utility patent
      AND "grant_date" BETWEEN 20100101 AND 20101231        -- granted in 2010
      AND "publication_number" IS NOT NULL
      AND "application_number" IS NOT NULL
      AND TRY_TO_DATE(TO_VARCHAR("filing_date"),'YYYYMMDD') IS NOT NULL
),
forward_cites AS (        /* citing publications within 10‑year window */
    SELECT
        tgt."publication_number"  AS cited_pub,
        tgt."application_number"  AS cited_app,
        cp."application_number"   AS citing_app
    FROM granted_2010 tgt
    JOIN PATENTS.PATENTS.PUBLICATIONS cp
         /* keep citing docs whose filing date parses correctly
            and falls within 10 years after the cited patent's filing date */
      ON TRY_TO_DATE(TO_VARCHAR(cp."filing_date"),'YYYYMMDD') IS NOT NULL
     AND TRY_TO_DATE(TO_VARCHAR(cp."filing_date"),'YYYYMMDD')
            <= DATEADD(year,10,tgt.filing_dt)
    , LATERAL FLATTEN(INPUT => cp."citation") f              -- explode citation array
    WHERE (f.value:"publication_number"::STRING = tgt."publication_number"
           OR f.value:"application_number"::STRING  = tgt."application_number")
      AND cp."application_number" IS NOT NULL
),
cite_counts AS (          /* count distinct citing applications per patent */
    SELECT
        cited_pub,
        COUNT(DISTINCT citing_app) AS cite_cnt
    FROM forward_cites
    GROUP BY cited_pub
)
SELECT COUNT(*) AS "NUM_UTILITY_PATENTS_WITH_ONE_FORWARD_CITATION_2010"
FROM cite_counts
WHERE cite_cnt = 1;       /* exactly one forward citation */