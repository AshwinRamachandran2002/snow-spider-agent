/* -------------------------------------------------------------
   US-B2 patents (granted 2015-2018) – originality à la Trajtenberg
   -------------------------------------------------------------
   Originality  = 1 − Σ_i (n_i / N)^2
     n_i : occurrences of IPC4 code i among all backward citations
     N   : total number of IPC4 occurrences in the backward citations
-----------------------------------------------------------------*/
WITH target_pubs AS (          -- 1. all US-B2 grants 2015-2018
    SELECT
        "publication_number"  AS pub_number
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "kind_code"    = 'B2'
      AND "grant_date" BETWEEN 20150101 AND 20181231
),

backward_citations AS (        -- 2. their cited publications
    SELECT
        p."publication_number"                                     AS pub_number ,
        cit.value:"publication_number"::string                     AS cited_pub_number
    FROM PATENTS.PATENTS.PUBLICATIONS  p
    JOIN target_pubs t
      ON t.pub_number = p."publication_number"
    ,   LATERAL FLATTEN(input => p."citation") cit
    WHERE cit.value:"publication_number" IS NOT NULL
),

cited_ipc4 AS (                -- 3. IPC-4 of every cited pub
    SELECT
        bc.pub_number ,
        LEFT(ipc_val.value:"code"::string,4)  AS ipc4
    FROM backward_citations bc
    JOIN PATENTS.PATENTS.PUBLICATIONS  cp
      ON cp."publication_number" = bc.cited_pub_number
    ,   LATERAL FLATTEN(input => cp."ipc") ipc_val
    WHERE ipc_val.value:"code" IS NOT NULL
),

ipc_counts AS (                -- 4. counts per IPC-4
    SELECT
        pub_number ,
        ipc4 ,
        COUNT(*) AS cnt
    FROM cited_ipc4
    GROUP BY pub_number , ipc4
),

totals AS (                    -- 5. total IPC occurrences
    SELECT
        pub_number ,
        SUM(cnt) AS total_cnt
    FROM ipc_counts
    GROUP BY pub_number
    HAVING SUM(cnt) > 0        -- avoid divide-by-zero
),

originality_scores AS (        -- 6. Trajtenberg originality
    SELECT
        ic.pub_number ,
        1 - (SUM(POWER(ic.cnt,2)) / POWER(t.total_cnt,2)) ::FLOAT  AS originality_score
    FROM ipc_counts ic
    JOIN totals      t ON t.pub_number = ic.pub_number
    GROUP BY ic.pub_number , t.total_cnt
)

SELECT
    pub_number            AS "publication_number_with_highest_originality" ,
    originality_score     AS "originality_score"
FROM originality_scores
ORDER BY originality_score DESC NULLS LAST
LIMIT 1;