WITH ipc_data AS (
    SELECT
        t."publication_number",
        SUBSTR(ipc_info.value:"code"::STRING, 1, 4) AS "ipc4_code"
    FROM PATENTS.PATENTS.PUBLICATIONS t,
    LATERAL FLATTEN(input => t."ipc") ipc_info
    WHERE t."country_code" = 'US' 
      AND t."kind_code" = 'B2' 
      AND t."grant_date" BETWEEN 20220601 AND 20220930
),
ipc_counts AS (
    SELECT
        "publication_number",
        "ipc4_code",
        COUNT(*) AS "ipc4_count"
    FROM ipc_data
    GROUP BY "publication_number", "ipc4_code"
),
most_frequent_ipc4 AS (
    SELECT
        "publication_number",
        "ipc4_code",
        ROW_NUMBER() OVER (
            PARTITION BY "publication_number" 
            ORDER BY "ipc4_count" DESC NULLS LAST
        ) AS "rank"
    FROM ipc_counts
),
ipc4_total_counts AS (
    SELECT
        "ipc4_code",
        COUNT(DISTINCT "publication_number") AS "ipc4_total_count"
    FROM ipc_data
    GROUP BY "ipc4_code"
),
result AS (
    SELECT
        mf."publication_number",
        mf."ipc4_code"
    FROM most_frequent_ipc4 mf
    JOIN ipc4_total_counts ic 
        ON mf."ipc4_code" = ic."ipc4_code"
    WHERE mf."rank" = 1 
      AND ic."ipc4_total_count" >= 10
)
SELECT "publication_number", "ipc4_code"
FROM result;