WITH focal AS (  -- all U.S. B2 grants 2015-2018
    SELECT "publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "kind_code"    = 'B2'
      AND "grant_date" BETWEEN 20150101 AND 20181231
),
cited AS (        -- backward-cited publication numbers for each focal patent
    SELECT
        p."publication_number"                          AS "focal_pub",
        f.value:"publication_number"::STRING            AS "cited_pub"
    FROM PATENTS.PATENTS.PUBLICATIONS p
    JOIN focal
      ON p."publication_number" = focal."publication_number"
    ,  LATERAL FLATTEN(input => p."citation") f
    WHERE f.value:"publication_number" IS NOT NULL
),
ipc_freq AS (     -- 4-digit IPC frequencies among the cited patents
    SELECT
        cited."focal_pub",
        SUBSTR(ipc_f.value:"code"::STRING, 1, 4)        AS "ipc4",
        COUNT(*)                                        AS "occ"
    FROM cited
    JOIN PATENTS.PATENTS.PUBLICATIONS c
      ON c."publication_number" = cited."cited_pub"
    ,  LATERAL FLATTEN(input => c."ipc") ipc_f
    WHERE ipc_f.value:"code" IS NOT NULL
    GROUP BY cited."focal_pub", "ipc4"
),
stats AS (        -- totals required for originality
    SELECT
        "focal_pub",
        SUM("occ")                        AS "tot",
        SUM(POWER("occ", 2))              AS "sum_sq"
    FROM ipc_freq
    GROUP BY "focal_pub"
    HAVING SUM("occ") > 0
)
SELECT
    "focal_pub"                                           AS "publication_number",
    1 - ("sum_sq" / POWER("tot", 2))                      AS "originality"
FROM stats
ORDER BY "originality" DESC NULLS LAST
LIMIT 1;