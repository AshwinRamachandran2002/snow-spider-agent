WITH 

/* 1.  focal US-grant (B2) publications, granted 2015-2018 */
focal_pub AS (
    SELECT 
        "publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "kind_code"   = 'B2'
      AND "grant_date" BETWEEN 20150101 AND 20181231
),

/* 2.  Main 4-digit IPC for every publication (use row-number to
       prioritise the element where "first" = true, otherwise pick
       alphabetically-minimal code)                                          */
cited_ipc_ranked AS (
    SELECT
        p."publication_number"                          AS "cited_pub",
        SUBSTR(ipc_flat.value:"code"::STRING,1,4)       AS "ipc4",
        ROW_NUMBER() OVER (
            PARTITION BY p."publication_number"
            ORDER BY (ipc_flat.value:"first"::BOOLEAN) DESC NULLS LAST,
                     ipc_flat.value:"code"::STRING
        )                                              AS rn
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(INPUT => p."ipc") ipc_flat
    WHERE p."ipc" IS NOT NULL
),
cited_ipc AS (
    SELECT "cited_pub", "ipc4"
    FROM   cited_ipc_ranked
    WHERE  rn = 1            -- keep only the selected main IPC
),

/* 3.  Expand backward citations of each focal publication                */
citations AS (
    SELECT
        fp."publication_number"                       AS "focal_pub",
        c.value:"publication_number"::STRING          AS "cited_pub"
    FROM PATENTS.PATENTS.PUBLICATIONS fp
    JOIN focal_pub f
      ON fp."publication_number" = f."publication_number",
         LATERAL FLATTEN(INPUT => fp."citation") c
    WHERE c.value:"publication_number" IS NOT NULL
),

/* 4.  Attach IPC of cited patents                                        */
cited_with_ipc AS (
    SELECT
        ct."focal_pub",
        ci."ipc4"
    FROM citations ct
    JOIN cited_ipc ci
      ON ct."cited_pub" = ci."cited_pub"
    WHERE ci."ipc4" IS NOT NULL
),

/* 5.  Counts per (focal, IPC4)                                           */
counts AS (
    SELECT
        "focal_pub",
        "ipc4",
        COUNT(*) AS "cnt"
    FROM cited_with_ipc
    GROUP BY "focal_pub", "ipc4"
),

/* 6.  Total cited-patent count per focal publication                     */
totals AS (
    SELECT
        "focal_pub",
        SUM("cnt") AS "total_cnt"
    FROM counts
    GROUP BY "focal_pub"
),

/* 7.  Originality calculation: 1 - Σ(cnt²)/(total²)                      */
orig AS (
    SELECT
        c."focal_pub",
        1 - SUM(POWER(c."cnt",2)) / POWER(t."total_cnt",2) AS "originality"
    FROM counts c
    JOIN totals t
      ON c."focal_pub" = t."focal_pub"
    GROUP BY c."focal_pub", t."total_cnt"
)

/* 8.  Return the patent with the highest originality score               */
SELECT
    "focal_pub"   AS "publication_number",
    "originality"
FROM orig
ORDER BY "originality" DESC NULLS LAST
LIMIT 1;