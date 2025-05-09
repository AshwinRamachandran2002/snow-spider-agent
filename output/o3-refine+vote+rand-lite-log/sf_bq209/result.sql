WITH target_patents AS (   -- utility patents granted in 2010
    SELECT
        "publication_number"                                 AS target_pub,
        "application_number"                                 AS target_app,
        TRY_TO_DATE("filing_date"::STRING,'YYYYMMDD')        AS target_filing_dt
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "application_kind" = 'A'                          -- utility patent
      AND "grant_date" BETWEEN 20100101 AND 20101231        -- granted in 2010
      AND TRY_TO_DATE("filing_date"::STRING,'YYYYMMDD') IS NOT NULL
),

forward_citations AS (      -- forward‑citation counts within 10 years
    SELECT
        t.target_pub,
        COUNT(DISTINCT c."application_number") AS fwd_ct
    FROM target_patents               t
    JOIN PATENTS.PATENTS.PUBLICATIONS c          -- potential citing docs
          ON TRUE
    ,   LATERAL FLATTEN(c."citation") cit        -- one row per cited reference
    WHERE cit.value:"publication_number"::STRING = t.target_pub      -- cites target
      AND c."application_number" <> t.target_app                      -- exclude self‑cites
      AND TRY_TO_DATE(c."filing_date"::STRING,'YYYYMMDD') IS NOT NULL
      AND TRY_TO_DATE(c."filing_date"::STRING,'YYYYMMDD')  >  t.target_filing_dt
      AND TRY_TO_DATE(c."filing_date"::STRING,'YYYYMMDD') <= DATEADD(year,10,t.target_filing_dt)
    GROUP BY t.target_pub
),

patents_with_one_fwd AS (   -- keep only those with exactly one forward citation
    SELECT t.target_pub
    FROM   target_patents t
    LEFT   JOIN forward_citations f
           ON t.target_pub = f.target_pub
    WHERE  COALESCE(f.fwd_ct,0) = 1
)

SELECT COUNT(*) AS num_utility_patents_granted_2010_with_one_fwd_cite_in_10yrs
FROM patents_with_one_fwd;