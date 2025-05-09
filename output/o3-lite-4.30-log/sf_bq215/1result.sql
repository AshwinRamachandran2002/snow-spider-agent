WITH focal AS (
    SELECT "publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "kind_code"    = 'B2'
      AND "grant_date"  BETWEEN 20150101 AND 20181231
),
backward AS (
    SELECT 
        t."publication_number"                     AS "focal_pub",
        f.value:"publication_number"::STRING       AS "cited_pub"
    FROM PATENTS.PATENTS.PUBLICATIONS t
    JOIN focal ON focal."publication_number" = t."publication_number",
         LATERAL FLATTEN(input => t."citation") f
    WHERE f.value:"publication_number" IS NOT NULL
),
ipc_flat AS (
    SELECT 
        b."focal_pub",
        b."cited_pub",
        SUBSTR(ipc_f.value:"code"::STRING, 1, 4)   AS "ipc4"
    FROM backward b
    JOIN PATENTS.PATENTS.PUBLICATIONS p
      ON p."publication_number" = b."cited_pub",
         LATERAL FLATTEN(input => p."ipc") ipc_f
),
ipc_counts AS (
    SELECT 
        "focal_pub",
        "ipc4",
        COUNT(DISTINCT "cited_pub")                AS n
    FROM ipc_flat
    GROUP BY "focal_pub", "ipc4"
),
totals AS (
    SELECT "focal_pub", SUM(n) AS Ntot
    FROM ipc_counts
    GROUP BY "focal_pub"
    HAVING SUM(n) > 0
),
orig AS (
    SELECT 
        c."focal_pub"                              AS patent_id,
        ROUND(
            1 - SUM(c.n * c.n) / (t.Ntot * t.Ntot),
            4
        )                                          AS originality_score
    FROM ipc_counts c
    JOIN totals t
      ON t."focal_pub" = c."focal_pub"
    GROUP BY c."focal_pub", t.Ntot
)
SELECT patent_id, originality_score
FROM orig
ORDER BY originality_score DESC NULLS LAST, patent_id
LIMIT 1;