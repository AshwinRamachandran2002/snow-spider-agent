WITH candidate AS (  -- US patents with B2 kind code granted between 2015-2018
    SELECT "publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "kind_code"   = 'B2'
      AND "grant_date" BETWEEN 20150101 AND 20181231
),
backward AS (        -- flatten backward citations
    SELECT
        p."publication_number"                           AS patent,
        f.value:"publication_number"::STRING             AS cited_pub
    FROM PATENTS.PATENTS.PUBLICATIONS p
    JOIN candidate c
          ON p."publication_number" = c."publication_number"
    ,    LATERAL FLATTEN(input => p."citation") f
    WHERE f.value:"publication_number" IS NOT NULL
),
ipc_flat AS (        -- fetch & flatten IPCs of the cited patents, keep 4-digit codes
    SELECT
        b.patent,
        SUBSTR(i.value:"code"::STRING, 1, 4)             AS ipc4
    FROM backward b
    JOIN PATENTS.PATENTS.PUBLICATIONS cp
          ON cp."publication_number" = b.cited_pub
    ,    LATERAL FLATTEN(input => cp."ipc") i
    WHERE i.value:"code" IS NOT NULL
),
counts AS (          -- occurrences of each 4-digit IPC among backward citations
    SELECT
        patent,
        ipc4,
        COUNT(*)                                         AS cnt
    FROM ipc_flat
    GROUP BY patent, ipc4
),
agg AS (             -- prepare pieces for originality
    SELECT
        patent,
        SUM(cnt)                    AS total_cnt,
        SUM(cnt*cnt)                AS sum_sq
    FROM counts
    GROUP BY patent
),
orig AS (            -- Trajtenberg originality score
    SELECT
        patent                       AS "publication_number",
        1 - (sum_sq::FLOAT)/(total_cnt*total_cnt) AS originality
    FROM agg
    WHERE total_cnt > 0
)
SELECT
    "publication_number",
    originality
FROM orig
ORDER BY originality DESC NULLS LAST
LIMIT 1;