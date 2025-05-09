/*  number of utility patents granted in 2010 that received
    exactly ONE distinct forward-citation (by application number)
    within 10 years from their own filing date               */

WITH source_patents AS (          -- utility patents granted in 2010
    SELECT
        "publication_number",
        "application_number_formatted",
        TO_DATE("filing_date"::VARCHAR , 'YYYYMMDD')  AS filing_dt
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "grant_date"        BETWEEN 20100101 AND 20101231     -- granted in 2010
      AND "application_kind"   = 'A'                             -- utility patents
      AND "filing_date"        IS NOT NULL
),

citations_expanded AS (          -- explode every citation (citing  ->  cited)
    SELECT
        f.value:publication_number::STRING                     AS cited_pub,
        cp."application_number_formatted"                      AS citing_app,
        TO_DATE(cp."filing_date"::VARCHAR , 'YYYYMMDD')        AS citing_filing_dt
    FROM PATENTS.PATENTS.PUBLICATIONS cp,
         LATERAL FLATTEN ( INPUT => cp."citation" ) f
    WHERE cp."application_number_formatted" IS NOT NULL
      AND cp."filing_date" IS NOT NULL
),

citing_links AS (                -- keep only citations that point to 2010-granted patents
    SELECT
        sp."publication_number"  AS target_pub,
        ce.citing_app,
        ce.citing_filing_dt
    FROM source_patents     sp
    JOIN citations_expanded ce
      ON ce.cited_pub = sp."publication_number"
),

filtered_citing_links AS (       -- citations made within 10 years of target’s filing date
    SELECT
        cl.target_pub,
        cl.citing_app
    FROM citing_links       cl
    JOIN source_patents     sp
      ON sp."publication_number" = cl.target_pub
    WHERE cl.citing_filing_dt BETWEEN sp.filing_dt
                                  AND DATEADD(year, 10, sp.filing_dt)
)

SELECT COUNT(*) AS "NUM_UTILITY_PATENTS_GRANTED_2010_WITH_ONE_FORWARD_CITATION"
FROM (
    SELECT target_pub
    FROM   filtered_citing_links
    GROUP  BY target_pub
    HAVING COUNT(DISTINCT citing_app) = 1      -- exactly one forward citation
) t;