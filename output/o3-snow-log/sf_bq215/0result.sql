WITH us_b2 AS (   -- 1. US patents, B2 grants, 2015-2018
    SELECT "publication_number"
    FROM PATENTS.PATENTS.PUBLICATIONS
    WHERE "country_code" = 'US'
      AND "kind_code"   = 'B2'
      AND "grant_date" BETWEEN 20150101 AND 20181231
),

backward_citations AS (         -- 2. their backward-citation publication numbers
    SELECT  p."publication_number"                            AS citing_pn ,
            c.value:"publication_number"::STRING              AS cited_pn
    FROM    PATENTS.PATENTS.PUBLICATIONS  p
    JOIN    us_b2                                           
           ON p."publication_number" = us_b2."publication_number"
         , LATERAL FLATTEN ( input => p."citation")  c
    WHERE   c.value:"publication_number" IS NOT NULL
),

cited_ipc4 AS (                 -- 3. 4-digit IPCs of every cited patent
    SELECT  bc.citing_pn ,
            SUBSTR(ipc_item.value:"code"::STRING , 1 , 4)     AS ipc4
    FROM    backward_citations              bc
    JOIN    PATENTS.PATENTS.PUBLICATIONS    cited
           ON cited."publication_number" = bc.cited_pn
         , LATERAL FLATTEN ( input => cited."ipc")  ipc_item
    WHERE   ipc_item.value:"code" IS NOT NULL
),

ipc_counts AS (                 -- 4. n_k : occurrences of each ipc4 per focal patent
    SELECT  citing_pn ,
            ipc4 ,
            COUNT(*)                          AS n_k
    FROM    cited_ipc4
    GROUP BY citing_pn , ipc4
),

stats AS (                      -- 5. N  and  Σ n_k²  per focal patent
    SELECT  citing_pn ,
            SUM(n_k)                          AS total_n ,
            SUM(POWER(n_k , 2))               AS sum_sq
    FROM    ipc_counts
    GROUP BY citing_pn
)

-- 6. Originality = 1 − Σ(n_k/N)²  and select the highest one
SELECT  citing_pn               AS "publication_number" ,
        1 - ( sum_sq / POWER(total_n , 2) )  AS originality_score
FROM    stats
WHERE   total_n > 0
ORDER BY originality_score DESC NULLS LAST
LIMIT 1;