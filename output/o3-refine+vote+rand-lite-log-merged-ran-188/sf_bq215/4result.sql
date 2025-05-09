WITH "citing_patents" AS (      -- US patents (B2) granted 2015‑2018
    SELECT
        "publication_number",
        "citation"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "kind_code"   = 'B2'
      AND "grant_date" BETWEEN 20150101 AND 20181231
),
"cited_pairs" AS (              -- each backward‑cited publication number
    SELECT
        cp."publication_number"                          AS "citing_pub",
        cited.value:"publication_number"::string         AS "cited_pub"
    FROM "citing_patents" cp,
         LATERAL FLATTEN(input => cp."citation") cited
    WHERE cited.value:"publication_number" IS NOT NULL
),
"cited_ipc" AS (                -- 4‑digit IPCs of the cited publications
    SELECT
        cp."citing_pub",
        SUBSTR(ipc_item.value:"code"::string,1,4)        AS "ipc4"
    FROM "cited_pairs" cp
    JOIN PATENTS.PATENTS.PUBLICATIONS citedp
          ON citedp."publication_number" = cp."cited_pub"
         ,LATERAL FLATTEN(input => citedp."ipc") ipc_item
    WHERE ipc_item.value:"code" IS NOT NULL
),
"counts" AS (                   -- occurrences per IPC4
    SELECT
        "citing_pub",
        "ipc4",
        COUNT(*)                                   AS "cnt"
    FROM "cited_ipc"
    GROUP BY "citing_pub","ipc4"
),
"agg" AS (                      -- sum of squares and totals
    SELECT
        "citing_pub",
        SUM("cnt" * "cnt")                        AS "sum_sq",
        SUM("cnt")                                AS "tot_cnt"
    FROM "counts"
    GROUP BY "citing_pub"
    HAVING SUM("cnt") > 0
),
"scores" AS (                   -- originality score
    SELECT
        "citing_pub",
        1 - ("sum_sq" / ("tot_cnt" * "tot_cnt"))  AS "originality"
    FROM "agg"
)
SELECT 
    "citing_pub" AS "publication_number",
    "originality"
FROM "scores"
ORDER BY "originality" DESC NULLS LAST, "publication_number"
LIMIT 1;