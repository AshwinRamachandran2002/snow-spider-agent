/*-------------------------------------------------------------*
 |  Highest-originality U.S. patent (kind-code B2, 2015-2018)  |
 *-------------------------------------------------------------*/
WITH focal AS (   /* candidate US-granted patents                */
    SELECT
        "publication_number",
        "citation"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "kind_code"   = 'B2'
      AND "grant_date" BETWEEN 20150101 AND 20181231
),

citations AS (    /* backward citations of each focal patent     */
    SELECT
        f."publication_number"                      AS focal_pub,
        c.value:"publication_number"::string        AS cited_pub
    FROM focal f,
         LATERAL FLATTEN(input => f."citation") c
    WHERE c.value:"publication_number" IS NOT NULL
),

cited_ipc AS (    /* 4-digit IPC codes of cited patents          */
    SELECT
        cit.focal_pub,
        SUBSTR(ipc_el.value:"code"::string, 1, 4)   AS ipc4
    FROM citations cit
    JOIN PATENTS.PATENTS.PUBLICATIONS p2
         ON p2."publication_number" = cit.cited_pub
    ,    LATERAL FLATTEN(input => p2."ipc") ipc_el
    WHERE ipc_el.value:"code" IS NOT NULL
),

ipc_counts AS (   /* occurrences of each IPC4 per focal patent   */
    SELECT
        focal_pub,
        ipc4,
        COUNT(*) AS occ
    FROM cited_ipc
    GROUP BY focal_pub, ipc4
),

stats AS (        /* sums needed for originality                 */
    SELECT
        focal_pub,
        SUM(occ)                  AS total_occ,
        SUM(occ * occ)            AS sum_sq
    FROM ipc_counts
    GROUP BY focal_pub
    HAVING SUM(occ) > 0           /* exclude patents w/ no data  */
),

originality AS (  /* Trajtenberg originality score               */
    SELECT
        focal_pub                           AS "publication_number",
        1 - (sum_sq / (total_occ * total_occ))  AS originality
    FROM stats
)

SELECT
    "publication_number",
    originality
FROM originality
ORDER BY originality DESC NULLS LAST
LIMIT 1;