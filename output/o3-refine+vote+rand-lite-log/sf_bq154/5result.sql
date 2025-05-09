/*  Kruskal‑Wallis H statistic for IGF2 expression across ICD‑O‑3 histology
    groups in LGG patients (Snowflake‑compatible)                        */

WITH expr_raw AS (          -- IGF2 expression for each aliquot
    SELECT
        g."ParticipantBarcode",
        c."icd_o_3_histology"                          AS histology,
        LOG(10, g."normalized_count" + 1)              AS log_expr          -- log10(x+1)
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"  g
    JOIN PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"            c
          ON g."ParticipantBarcode" = c."bcr_patient_barcode"
    WHERE g."Study"  = 'LGG'
      AND g."Symbol" = 'IGF2'
      AND g."normalized_count" IS NOT NULL
      AND c."icd_o_3_histology" IS NOT NULL
      AND NOT REGEXP_LIKE(c."icd_o_3_histology", '^\\[.*\\]$')              -- drop bracketed codes
),
patient_expr AS (           -- average IGF2 expression per patient
    SELECT
        "ParticipantBarcode",
        histology,
        AVG(log_expr) AS value
    FROM expr_raw
    GROUP BY "ParticipantBarcode", histology
),
valid_histology AS (        -- keep groups with > 1 patient
    SELECT histology
    FROM patient_expr
    GROUP BY histology
    HAVING COUNT(*) > 1
),
filtered AS (
    SELECT p.*
    FROM patient_expr p
    JOIN valid_histology v
      ON p.histology = v.histology
),
rank_base AS (              -- minimum rank and tie counts
    SELECT
        *,
        RANK()  OVER (ORDER BY value)      AS rnk_min,
        COUNT(*) OVER (PARTITION BY value) AS tie_cnt
    FROM filtered
),
ranks AS (                  -- average rank per observation (mid‑rank for ties)
    SELECT
        histology,
        (rnk_min + rnk_min + tie_cnt - 1) / 2.0 AS avg_rank
    FROM rank_base
),
grp_stats AS (              -- per‑group sums
    SELECT
        histology,
        COUNT(*)                     AS n_i,
        SUM(avg_rank)                AS S_i,
        SUM(POWER(avg_rank, 2))      AS Q_i
    FROM ranks
    GROUP BY histology
),
totals AS (                 -- overall totals
    SELECT
        SUM(n_i)                        AS N,
        SUM(S_i)                        AS SUM_S,
        SUM(Q_i)                        AS SUM_Q,
        SUM(POWER(S_i, 2) / n_i)        AS SUM_S2_OVER_N
    FROM grp_stats
),
h_calc AS (                 -- Kruskal‑Wallis H statistic
    SELECT
        ( (N - 1) *
          (SUM_S2_OVER_N - POWER(SUM_S, 2) / N) /
          (SUM_Q        - POWER(SUM_S, 2) / N)
        ) AS kruskal_wallis_H
    FROM totals
)
SELECT
    (SELECT COUNT(*) FROM grp_stats) AS total_groups,
    (SELECT N        FROM totals)    AS total_samples,
    (SELECT kruskal_wallis_H FROM h_calc) AS kruskal_wallis_H
ORDER BY kruskal_wallis_H DESC NULLS LAST;