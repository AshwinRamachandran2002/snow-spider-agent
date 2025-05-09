WITH filtered AS (
    /* 1.  United‑States B2 utility patents granted Jun‑Sep 2022 */
    SELECT 
        "publication_number",
        "ipc"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "kind_code"   = 'B2'
      AND "grant_date" BETWEEN 20220601 AND 20220930
), ipc4_expanded AS (
    /* 2.  Break out every IPC code and keep its first 4 characters            */
    SELECT
        f."publication_number",
        SUBSTR(ipc_item.value:"code"::string, 1, 4) AS ipc4
    FROM filtered f,
         LATERAL FLATTEN(input => f."ipc") ipc_item
    WHERE ipc_item.value:"code" IS NOT NULL
), ipc4_ranked AS (
    /* 3.  Count how often each IPC4 appears per patent and rank them          */
    SELECT
        "publication_number",
        ipc4,
        COUNT(*)                          AS ipc4_count,
        ROW_NUMBER() OVER (
            PARTITION BY "publication_number"
            ORDER BY COUNT(*) DESC, ipc4  /* tie‑breaker: alphabetic            */
        ) AS rn
    FROM ipc4_expanded
    GROUP BY "publication_number", ipc4
), main_ipc4 AS (
    /* 4.  Keep only the single most‑frequent IPC4 for every patent            */
    SELECT "publication_number", ipc4
    FROM   ipc4_ranked
    WHERE  rn = 1
), popular_ipc4 AS (
    /* 5.  IPC4 codes that are main code for ≥10 different patents             */
    SELECT ipc4
    FROM   main_ipc4
    GROUP  BY ipc4
    HAVING COUNT(*) >= 10
)
SELECT 
    m."publication_number",
    m.ipc4
FROM main_ipc4 m
JOIN popular_ipc4 p
  ON m.ipc4 = p.ipc4
ORDER BY m.ipc4, m."publication_number";