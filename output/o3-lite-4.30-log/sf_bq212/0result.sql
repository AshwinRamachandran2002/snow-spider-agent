WITH ipc_counts AS (
    SELECT
        p."publication_number",
        SUBSTR(f.value:"code"::STRING, 1, 4) AS "ipc4",
        COUNT(*) AS "freq"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(INPUT => p."ipc") f
    WHERE p."country_code"     = 'US'
      AND p."kind_code"        = 'B2'
      AND p."application_kind" = 'A'
      AND p."grant_date" BETWEEN 20220601 AND 20220930
      AND LENGTH(f.value:"code"::STRING) >= 4
    GROUP BY p."publication_number", "ipc4"
),
main_ipc AS (
    SELECT *
    FROM ipc_counts
    QUALIFY "freq" = MAX("freq") OVER (PARTITION BY "publication_number")
),
popular_ipc4 AS (
    SELECT "ipc4"
    FROM main_ipc
    GROUP BY "ipc4"
    HAVING COUNT(*) >= 10
)
SELECT
    m."publication_number",
    m."ipc4"
FROM main_ipc m
JOIN popular_ipc4 p
  ON m."ipc4" = p."ipc4"
ORDER BY
    m."ipc4",
    m."publication_number";