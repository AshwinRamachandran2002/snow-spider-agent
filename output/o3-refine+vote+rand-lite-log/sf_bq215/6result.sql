WITH "candidate" AS (
    SELECT
        "publication_number",
        "citation"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "kind_code"   = 'B2'
      AND "grant_date"  BETWEEN 20150101 AND 20181231
),
"cited" AS (
    SELECT
        c."publication_number"                               AS "citing_pub",
        f.value:"publication_number"::STRING                 AS "cited_pub"
    FROM "candidate" c,
         LATERAL FLATTEN(input => c."citation") f
    WHERE f.value:"publication_number" IS NOT NULL
),
"cited_ipc" AS (
    SELECT
        c."citing_pub",
        cp."publication_number"                              AS "cited_pub",
        ipc.value:"code"::STRING                             AS "ipc_code"
    FROM "cited" c
    JOIN PATENTS.PATENTS.PUBLICATIONS cp
      ON cp."publication_number" = c."cited_pub"
    ,  LATERAL FLATTEN(input => cp."ipc") ipc
    WHERE ipc.value:"code" IS NOT NULL
),
"ipc4_counts" AS (
    SELECT
        "citing_pub",
        SUBSTR("ipc_code",1,4)                               AS "ipc4",
        COUNT(*)                                             AS "cnt"
    FROM "cited_ipc"
    GROUP BY "citing_pub", "ipc4"
),
"originality_calc" AS (
    SELECT
        "citing_pub"                                         AS "publication_number",
        1 - (SUM("cnt"* "cnt")::FLOAT / POWER(SUM("cnt"),2)) AS "originality"
    FROM "ipc4_counts"
    GROUP BY "citing_pub"
)
SELECT
    "publication_number"
FROM "originality_calc"
ORDER BY "originality" DESC NULLS LAST, "publication_number"
LIMIT 1;