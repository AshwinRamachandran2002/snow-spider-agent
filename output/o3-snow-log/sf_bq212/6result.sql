WITH exploded_ipc AS (   -- break out every IPC code and cut to 4-digit level
    SELECT
        pub."publication_number",
        SUBSTR( ipc_item.value:"code"::STRING , 1 , 4 ) AS "ipc4"
    FROM
        PATENTS.PATENTS.PUBLICATIONS   pub,
        LATERAL FLATTEN( INPUT => pub."ipc" )           ipc_item
    WHERE
        pub."country_code"      = 'US'              -- United States
        AND pub."kind_code"     = 'B2'              -- granted (B2) publications
        AND pub."grant_date" BETWEEN 20220601
                                AND 20220930        -- June-Sept 2022
        AND pub."application_kind" IN ('A','U')     -- utility patents
),
ipc_counts AS (        -- count how often each IPC4 occurs inside each patent
    SELECT
        "publication_number",
        "ipc4",
        COUNT(*) AS "ipc4_count"
    FROM  exploded_ipc
    GROUP BY
        "publication_number",
        "ipc4"
),
patent_max AS (        -- highest frequency for every patent
    SELECT
        "publication_number",
        MAX("ipc4_count") AS "max_cnt"
    FROM ipc_counts
    GROUP BY "publication_number"
),
most_frequent_ipc AS ( -- IPC4s that reach the highest frequency per patent
    SELECT
        c."publication_number",
        c."ipc4",
        c."ipc4_count"
    FROM ipc_counts c
    JOIN patent_max  m
      ON  m."publication_number" = c."publication_number"
      AND m."max_cnt"            = c."ipc4_count"
)
SELECT
    "publication_number",
    "ipc4"
FROM
    most_frequent_ipc
WHERE
    "ipc4_count" >= 10           -- appears 10 or more times within the patent
ORDER BY
    "publication_number";