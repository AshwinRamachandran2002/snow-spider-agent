WITH citing AS (
    SELECT 
        "publication_number" AS citing_pub
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "kind_code"   = 'B2'
      AND "grant_date" BETWEEN 20150101 AND 20181231
),
citations AS (
    SELECT
        cp.citing_pub,
        c.value:"publication_number"::STRING AS cited_pub
    FROM citing cp
    JOIN PATENTS.PATENTS.PUBLICATIONS p 
          ON p."publication_number" = cp.citing_pub
    ,   LATERAL FLATTEN(input => p."citation") c
    WHERE c.value:"publication_number" IS NOT NULL
),
cited_ipc AS (
    SELECT
        ct.citing_pub,
        SUBSTR(ipc_v.value:"code"::STRING, 1, 4) AS ipc4
    FROM citations ct
    JOIN PATENTS.PATENTS.PUBLICATIONS p2
          ON p2."publication_number" = ct.cited_pub
    ,   LATERAL FLATTEN(input => p2."ipc") ipc_v
    WHERE ipc_v.value:"code" IS NOT NULL
),
ipc_counts AS (
    SELECT
        citing_pub,
        ipc4,
        COUNT(*) AS cnt
    FROM cited_ipc
    GROUP BY citing_pub, ipc4
),
agg AS (
    SELECT
        citing_pub,
        SUM(cnt * cnt) AS sum_sq,
        SUM(cnt)       AS tot
    FROM ipc_counts
    GROUP BY citing_pub
    HAVING SUM(cnt) > 0
),
orig AS (
    SELECT
        citing_pub,
        1 - (sum_sq::FLOAT / POWER(tot, 2)) AS originality
    FROM agg
)
SELECT 
    citing_pub AS "publication_number",
    originality
FROM orig
ORDER BY originality DESC NULLS LAST
LIMIT 1;