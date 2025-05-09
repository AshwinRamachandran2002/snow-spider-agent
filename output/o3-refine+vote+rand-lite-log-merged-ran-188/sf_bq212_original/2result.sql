WITH filtered AS (
    /* 1.  US utility patents (kind code B2, application kind A)
          granted between 1‑Jun‑2022 and 30‑Sep‑2022               */
    SELECT
        "publication_number",
        "ipc"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code"      = 'US'
      AND "kind_code"         = 'B2'
      AND "application_kind"  = 'A'
      AND "grant_date" BETWEEN 20220601 AND 20220930
),

/* 2.  Count occurrences of every 4‑digit IPC code inside each patent */
ipc4_counts AS (
    SELECT
        f."publication_number",
        LEFT(ipc_item.value:"code"::string, 4) AS "ipc4",
        COUNT(*)                               AS "cnt"
    FROM filtered f,
         LATERAL FLATTEN(input => f."ipc") ipc_item
    WHERE ipc_item.value:"code" IS NOT NULL
    GROUP BY f."publication_number",
             LEFT(ipc_item.value:"code"::string, 4)
),

/* 3.  For every patent keep the IPC4 with the highest within‑patent frequency */
primary_ipc4 AS (
    SELECT
        "publication_number",
        "ipc4",
        ROW_NUMBER() OVER (PARTITION BY "publication_number"
                           ORDER BY "cnt" DESC, "ipc4") AS rn
    FROM ipc4_counts
),
patent_main_ipc4 AS (
    SELECT "publication_number", "ipc4"
    FROM primary_ipc4
    WHERE rn = 1
),

/* 4.  Keep only those IPC4 codes that are the main code for ≥ 10 patents */
popular_ipc4 AS (
    SELECT "ipc4"
    FROM patent_main_ipc4
    GROUP BY "ipc4"
    HAVING COUNT(*) >= 10
)

/* 5.  Final list: patents whose main IPC4 appears at least 10 times overall */
SELECT
    p."publication_number",
    p."ipc4"
FROM patent_main_ipc4 p
JOIN popular_ipc4      pop USING ("ipc4")
ORDER BY
    p."ipc4",
    p."publication_number";