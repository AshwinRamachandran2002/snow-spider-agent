WITH expr AS (                                                      -- ①  log10-transformed IGF2 expression
    SELECT
        c."icd_o_3_histology"               AS "Histology",
        LOG(10, e."normalized_count" + 1)   AS "log_expr"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"      c
    JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" e
          ON c."bcr_patient_barcode" = e."ParticipantBarcode"
    WHERE e."Symbol" = 'IGF2'
      AND e."normalized_count" IS NOT NULL
      AND NOT c."icd_o_3_histology" RLIKE '^\\[.*\\]$'              -- exclude bracketed codes
),
ranks AS (                                                           -- ②  raw ranks
    SELECT
        "Histology",
        "log_expr",
        RANK() OVER (ORDER BY "log_expr") AS raw_rank
    FROM expr
),
ranked AS (                                                          -- ③  average rank for ties
    SELECT
        "Histology",
        AVG(raw_rank) OVER (PARTITION BY "log_expr") AS rank
    FROM ranks
),
per_grp AS (                                                         -- ④  Sᵢ, Qᵢ, nᵢ  (groups with >1 sample)
    SELECT
        "Histology",
        COUNT(*)               AS n_i,
        SUM(rank)              AS S_i,
        SUM(POWER(rank,2))     AS Q_i
    FROM ranked
    GROUP BY "Histology"
    HAVING COUNT(*) > 1
),
totals AS (                                                          -- ⑤  overall totals
    SELECT
        COUNT(*)  AS g,          -- number of groups
        SUM(n_i)  AS N,          -- total samples
        SUM(S_i)  AS sumS,
        SUM(Q_i)  AS sumQ
    FROM per_grp
),
aux AS (                                                             -- ⑥  Σ(Sᵢ² / nᵢ)
    SELECT SUM(POWER(S_i,2) / n_i) AS sum_S2_div_n
    FROM per_grp
)
SELECT                                                                -- ⑦  Kruskal-Wallis H
    totals.g  AS "n_groups",
    totals.N  AS "n_samples",
    ( totals.N - 1 ) *
    ( aux.sum_S2_div_n - POWER(totals.sumS,2) / totals.N ) /
    ( totals.sumQ      - POWER(totals.sumS,2) / totals.N ) AS "kruskal_wallis_H"
FROM totals
CROSS JOIN aux
ORDER BY "kruskal_wallis_H" DESC NULLS LAST;