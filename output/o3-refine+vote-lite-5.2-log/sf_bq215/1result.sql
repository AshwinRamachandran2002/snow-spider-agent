WITH candidate_patents AS (        -- US‑B2 grants between 2015‑2018
    SELECT
        "publication_number"                    AS focal_pub
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code"  = 'US'
      AND "kind_code"     = 'B2'
      AND "grant_date" BETWEEN 20150101 AND 20181231
),

/* backward citations of the candidate patents */
citations AS (
    SELECT
        p."publication_number"                                   AS focal_pub,
        c.value:"publication_number"::string                     AS cited_pub
    FROM PATENTS.PATENTS.PUBLICATIONS p
    JOIN candidate_patents cp
          ON p."publication_number" = cp.focal_pub
    ,     LATERAL FLATTEN(input => p."citation") c
    WHERE c.value:"publication_number" IS NOT NULL
),

/* count each 4‑digit IPC within every publication */
ipc_counts AS (
    SELECT
        pub."publication_number"                 AS pub_num,
        SUBSTR(f.value:"code"::string, 1, 4)     AS ipc4,
        COUNT(*)                                 AS cnt
    FROM PATENTS.PATENTS.PUBLICATIONS pub,
         LATERAL FLATTEN(input => pub."ipc") f
    GROUP BY pub."publication_number", ipc4
),

/* select the most frequent 4‑digit IPC per publication */
ipc_main AS (
    SELECT
        pub_num               AS publication_number,
        ipc4
    FROM (
        SELECT
            pub_num,
            ipc4,
            ROW_NUMBER() OVER (PARTITION BY pub_num
                               ORDER BY cnt DESC, ipc4) AS rn
        FROM ipc_counts
    )
    WHERE rn = 1
),

/* attach main IPC of every cited patent */
cited_ipc AS (
    SELECT
        cit.focal_pub,
        im.ipc4
    FROM citations cit
    JOIN ipc_main im
          ON cit.cited_pub = im.publication_number
),

/* occurrences of each IPC4 in the backward‑citation set */
class_freq AS (
    SELECT
        focal_pub,
        ipc4,
        COUNT(*) AS class_count
    FROM cited_ipc
    GROUP BY focal_pub, ipc4
),

/* total number of cited patents per focal patent */
totals AS (
    SELECT
        focal_pub,
        SUM(class_count) AS total_cited
    FROM class_freq
    GROUP BY focal_pub
),

/* originality score */
originality_scores AS (
    SELECT
        t.focal_pub                                 AS publication_number,
        1 - SUM(POWER(cf.class_count, 2))
            / POWER(t.total_cited, 2)               AS originality
    FROM class_freq cf
    JOIN totals t
          ON cf.focal_pub = t.focal_pub
    WHERE t.total_cited > 0
    GROUP BY t.focal_pub, t.total_cited
)

SELECT publication_number
FROM originality_scores
ORDER BY originality DESC NULLS LAST, publication_number
LIMIT 1;