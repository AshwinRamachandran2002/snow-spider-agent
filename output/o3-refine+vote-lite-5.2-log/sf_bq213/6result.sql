WITH ipc_counts AS (
    SELECT
        SUBSTR(f.value:"code"::STRING, 1, 4) AS IPC4,
        COUNT(*)                             AS CNT
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."ipc") f
    WHERE p."country_code" = 'US'
      AND p."kind_code"    = 'B2'                 -- granted utility patents
      AND p."grant_date" BETWEEN 20220601 AND 20220831   -- Jun–Aug 2022
    GROUP BY SUBSTR(f.value:"code"::STRING, 1, 4)
)
SELECT IPC4
FROM ipc_counts
ORDER BY CNT DESC NULLS LAST, IPC4
LIMIT 1;