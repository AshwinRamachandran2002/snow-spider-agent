WITH focal AS (   -- 1) US-B2 patents granted 2015-2018
    SELECT 
        "publication_number",
        "citation"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "kind_code"   = 'B2'
      AND "grant_date" BETWEEN 20150101 AND 20181231
),                                                   -- 2) cited publication numbers
cited_pubs AS (
    SELECT
        f."publication_number"           AS focal_pub,
        cp.value:"publication_number"::string AS cited_pub
    FROM focal f,
         LATERAL FLATTEN(input => f."citation") cp
    WHERE cp.value:"publication_number" IS NOT NULL
),                                                   -- 3) IPC-4 codes of cited patents
cited_ipc4 AS (
    SELECT
        c.focal_pub,
        SUBSTR(ipc_item.value:"code"::string,1,4) AS ipc4
    FROM cited_pubs               c
    JOIN PATENTS.PATENTS.PUBLICATIONS p
         ON p."publication_number" = c.cited_pub
    ,    LATERAL FLATTEN(input => p."ipc") ipc_item
    WHERE ipc_item.value:"code" IS NOT NULL
      AND LENGTH(ipc_item.value:"code"::string) >= 4
),                                                   -- 4) count of each IPC-4 among citations
ipc_counts AS (
    SELECT
        focal_pub,
        ipc4,
        COUNT(*) AS cnt
    FROM cited_ipc4
    GROUP BY focal_pub, ipc4
),                                                   -- 5) originality score
originality AS (
    SELECT
        focal_pub,
        1 - (SUM(POWER(cnt,2)) / POWER(SUM(cnt),2)) AS originality_score
    FROM ipc_counts
    GROUP BY focal_pub
)                                                   -- 6) patent with highest originality
SELECT 
    focal_pub          AS "publication_number",
    originality_score  AS "originality_score"
FROM originality
ORDER BY originality_score DESC NULLS LAST
LIMIT 1;