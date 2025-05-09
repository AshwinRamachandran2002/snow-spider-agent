WITH us_grants AS (      -- US‑B2 patents granted 2015‑2018
    SELECT
        "publication_number"      AS focal_pub,
        "citation"
    FROM "PATENTS"."PATENTS"."PUBLICATIONS"
    WHERE "country_code" = 'US'
      AND "kind_code"    = 'B2'
      AND "grant_date"  BETWEEN 20150101 AND 20181231
),
backward AS (              -- every backward‑cited publication number
    SELECT
        g.focal_pub,
        c.value:"publication_number"::STRING AS cited_pub
    FROM us_grants g,
         LATERAL FLATTEN(input => g."citation") c
    WHERE c.value:"publication_number" IS NOT NULL
),
cited_ipc4 AS (            -- 4‑digit IPC codes of the cited patents
    SELECT
        b.focal_pub,
        SUBSTR(ip.value:"code"::STRING,1,4) AS ipc4
    FROM backward b
    JOIN "PATENTS"."PATENTS"."PUBLICATIONS" p
      ON p."publication_number" = b.cited_pub
    ,    LATERAL FLATTEN(input => p."ipc") ip
    WHERE ip.value:"code" IS NOT NULL
),
ipc4_counts AS (           -- frequency of each IPC4 per focal patent
    SELECT
        focal_pub,
        ipc4,
        COUNT(*) AS n
    FROM cited_ipc4
    GROUP BY focal_pub, ipc4
)
SELECT
    focal_pub                                              AS patent_id,
    ROUND( 1 - SUM(POWER(n,2)) / NULLIF(POWER(SUM(n),2),0) , 4)
                                                           AS originality_score
FROM ipc4_counts
GROUP BY focal_pub
ORDER BY originality_score DESC NULLS LAST, patent_id
LIMIT 1;