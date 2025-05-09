WITH cited_ipc AS (
    /* -----------------------------------------------------------
       Pull every (focal patent  -> 4‑digit IPC of each cited patent)
       ----------------------------------------------------------- */
    SELECT
        fp."publication_number"                                             AS "focal_pub",
        SUBSTR(ipc_f.value:"code"::STRING, 1, 4)                            AS "ipc4"
    FROM PATENTS.PATENTS.PUBLICATIONS                 fp
    ,    LATERAL FLATTEN(input => fp."citation")      cit_f
    ,    PATENTS.PATENTS.PUBLICATIONS                 cited
    ,    LATERAL FLATTEN(input => cited."ipc")        ipc_f
    WHERE fp."country_code" = 'US'
      AND fp."kind_code"   = 'B2'
      AND fp."grant_date" BETWEEN 20150101 AND 20181231
      AND cit_f.value:"publication_number" IS NOT NULL
      AND cited."publication_number" = cit_f.value:"publication_number"::STRING
      AND ipc_f.value:"code" IS NOT NULL
),
ipc_counts AS (
    /* -----------------------------------------------------------
       Count how many times each distinct 4‑digit IPC appears
       in the backward citations of the focal patent
       ----------------------------------------------------------- */
    SELECT
        "focal_pub",
        "ipc4",
        COUNT(*)                                     AS cnt
    FROM cited_ipc
    GROUP BY "focal_pub", "ipc4"
),
agg AS (
    /* -----------------------------------------------------------
       Aggregate the counts needed for the originality formula
       ----------------------------------------------------------- */
    SELECT
        "focal_pub",
        SUM(cnt)                                    AS total_cnt,
        SUM(POWER(cnt, 2))                          AS sum_sq
    FROM ipc_counts
    GROUP BY "focal_pub"
)
SELECT
    "focal_pub"                                     AS "publication_number",
    1 - (sum_sq / POWER(total_cnt, 2))              AS "originality"
FROM agg
ORDER BY "originality" DESC NULLS LAST, "publication_number" ASC
LIMIT 1;