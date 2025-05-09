/*  Most-frequent IPC4 per U.S. B2 utility patent granted 2022-06-01 – 2022-09-30,
    keeping only those IPC4 groups that occur in ≥10 distinct patents          */

WITH per_publication AS (      -- pick the most-frequent IPC4 inside each patent
    SELECT
        p."publication_number",
        SUBSTR(f.value:"code"::STRING,1,4)                AS "ipc4",
        ROW_NUMBER() OVER (
            PARTITION BY p."publication_number"
            ORDER BY COUNT(*) DESC,
                     SUBSTR(f.value:"code"::STRING,1,4)
        )                                                AS rn
    FROM PATENTS.PATENTS.PUBLICATIONS       p,
         LATERAL FLATTEN(input => p."ipc") f
    WHERE p."country_code"   = 'US'
      AND p."kind_code"      = 'B2'          -- granted utility patents
      AND p."grant_date" BETWEEN 20220601 AND 20220930
    GROUP BY
        p."publication_number",
        SUBSTR(f.value:"code"::STRING,1,4)
),

ipc4_totals AS (              -- how many patents contain each IPC4
    SELECT
        SUBSTR(f.value:"code"::STRING,1,4)                AS "ipc4",
        COUNT(DISTINCT p."publication_number")            AS patent_cnt
    FROM PATENTS.PATENTS.PUBLICATIONS       p,
         LATERAL FLATTEN(input => p."ipc") f
    WHERE p."country_code"   = 'US'
      AND p."kind_code"      = 'B2'
      AND p."grant_date" BETWEEN 20220601 AND 20220930
    GROUP BY
        SUBSTR(f.value:"code"::STRING,1,4)
    HAVING COUNT(DISTINCT p."publication_number") >= 10   -- keep frequent IPC4s
)

SELECT
    pp."publication_number",
    pp."ipc4"
FROM per_publication pp
JOIN ipc4_totals    it
  ON pp."ipc4" = it."ipc4"
WHERE pp.rn = 1                    -- only the chosen most-frequent IPC4 per patent
ORDER BY
    pp."ipc4",
    pp."publication_number";