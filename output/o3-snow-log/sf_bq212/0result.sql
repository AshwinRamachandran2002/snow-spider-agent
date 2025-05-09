/* 1)  Select US utility patents (kind_code = 'B2', application_kind = 'A')
       granted between 2022-06-01 and 2022-09-30                                 */
WITH us_b2_2022 AS (
    SELECT
        p."publication_number",
        p."ipc"
    FROM PATENTS.PATENTS.PUBLICATIONS p
    WHERE p."country_code" = 'US'
      AND p."kind_code"   = 'B2'
      AND p."application_kind" = 'A'              -- utility patents
      AND p."grant_date" BETWEEN 20220601 AND 20220930
),

/* 2)  Flatten the IPC array and keep the first-four-character IPC string        */
ipc_flat AS (
    SELECT
        ub."publication_number",
        SUBSTR(TO_VARCHAR(ipc_f.value:"code"), 1, 4) AS "ipc4"
    FROM us_b2_2022 ub,
         LATERAL FLATTEN(input => ub."ipc") ipc_f
    WHERE ipc_f.value:"code" IS NOT NULL
),

/* 3)  Count occurrences of each IPC4 within each patent                         */
ipc_counts AS (
    SELECT
        "publication_number",
        "ipc4",
        COUNT(*) AS "cnt"
    FROM ipc_flat
    GROUP BY "publication_number", "ipc4"
),

/* 4)  For every patent, keep the most frequent IPC4 (break ties alphabetically) */
ipc_ranked AS (
    SELECT
        "publication_number",
        "ipc4",
        "cnt",
        ROW_NUMBER() OVER (PARTITION BY "publication_number"
                           ORDER BY "cnt" DESC, "ipc4" ASC) AS "rn"
    FROM ipc_counts
)

/* 5)  Return patents whose top IPC4 occurs ≥ 10 times                           */
SELECT
    "publication_number",
    "ipc4"
FROM ipc_ranked
WHERE "rn" = 1
  AND "cnt" >= 10
ORDER BY "publication_number" NULLS LAST;