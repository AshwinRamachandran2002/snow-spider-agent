WITH flattened AS (
    /*--- break out every IPC code and trim to 4-digit level ---*/
    SELECT
        p."publication_number",
        SUBSTR(f.value:"code"::STRING, 1, 4) AS "ipc4"
    FROM PATENTS.PATENTS.PUBLICATIONS p,
         LATERAL FLATTEN(input => p."ipc") f
    WHERE p."country_code"      = 'US'
      AND p."kind_code" ILIKE  '%B2%'      -- granted utility patents
      AND p."application_kind"  = 'A'      -- utility-patent applications
      AND p."publication_date" BETWEEN 20220601 AND 20220930
), ranked AS (
    /*--- within each patent keep the most-frequent IPC4 (ties -> alphabetic) ---*/
    SELECT
        "publication_number",
        "ipc4",
        COUNT(*)                                             AS "ipc4_in_patent_cnt",
        ROW_NUMBER() OVER (
            PARTITION BY "publication_number"
            ORDER BY COUNT(*) DESC, "ipc4"
        )                                                    AS rn
    FROM flattened
    GROUP BY "publication_number", "ipc4"
), top_ipc4 AS (
    SELECT "publication_number", "ipc4"
    FROM   ranked
    WHERE  rn = 1                               -- one row per patent
), popular_ipc4 AS (
    /*--- IPC4s that are the “top” code in ≥10 patents ---*/
    SELECT "ipc4"
    FROM   top_ipc4
    GROUP BY "ipc4"
    HAVING COUNT(*) >= 10
)
SELECT
    t."publication_number",
    t."ipc4"
FROM   top_ipc4  t
JOIN   popular_ipc4 p
  ON   t."ipc4" = p."ipc4"
ORDER BY t."ipc4", t."publication_number";