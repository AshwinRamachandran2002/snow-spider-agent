/*  Kruskal–Wallis test for IGF2 expression (log10(normalized_count+1) averaged per patient)
    across ICD-O-3 histology groups of TCGA-LGG patients.                     */

WITH lgg_hist_codes AS (                       -- ICD-O-3 codes generally used for LGG
    SELECT column1 AS code
    FROM ( VALUES  ('9382/3'),   -- oligodendroglioma / oligo-astrocytoma
                   ('9400/3'),   -- diffuse astrocytoma
                   ('9401/3'),   -- anaplastic astrocytoma
                   ('9450/3'),   -- oligodendroglioma
                   ('9451/3') )  -- anaplastic oligodendroglioma
),

/* --------------------------------------------------------------------------
   1.  One IGF2 expression value (log10(normalized_count + 1) mean) per patient
   -------------------------------------------------------------------------- */
expr_per_patient AS (
    SELECT
        g."ParticipantBarcode"                           AS patient,
        AVG( LOG(10, g."normalized_count" + 1) )         AS expr
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" g
    JOIN   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"            c
           ON c."bcr_patient_barcode" = g."ParticipantBarcode"
    JOIN   lgg_hist_codes h
           ON c."icd_o_3_histology" = h.code             -- keep LGG only
    WHERE  g."Symbol" = 'IGF2'
      AND  g."normalized_count" IS NOT NULL
    GROUP  BY g."ParticipantBarcode"
),

/* --------------------------------------------------------------------------
   2.  Rank the patients (average-rank for ties, two–pass trick)
   -------------------------------------------------------------------------- */
rank_step1 AS (        -- simple integer ranks
    SELECT
        patient,
        expr,
        RANK() OVER (ORDER BY expr)                      AS rnk
    FROM expr_per_patient
),
rank_step2 AS (        -- average rank for tied expression values
    SELECT
        patient,
        AVG(rnk) OVER (PARTITION BY expr)                AS rank_val
    FROM rank_step1
),

/* --------------------------------------------------------------------------
   3.  Attach ICD-O-3 code and build per-group aggregates  nᵢ , Sᵢ , Qᵢ
   -------------------------------------------------------------------------- */
patient_hist AS (
    SELECT
        c."icd_o_3_histology"                            AS hist_code,
        r.rank_val
    FROM   rank_step2                                   r
    JOIN   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
           ON c."bcr_patient_barcode" = r.patient
    WHERE  c."icd_o_3_histology" IN (SELECT code FROM lgg_hist_codes)
      AND  NOT REGEXP_LIKE(c."icd_o_3_histology", '^\\[.*\\]$')       -- drop bracketed codes
),
group_stats AS (
    SELECT
        hist_code,
        COUNT(*)                              AS n_i,                 -- group size
        SUM(rank_val)                         AS S_i,                 -- Σ ranks
        SUM(POWER(rank_val,2))                AS Q_i                  -- Σ ranks²
    FROM patient_hist
    GROUP BY hist_code
    HAVING COUNT(*) > 1                                           -- keep groups >1
),

/* --------------------------------------------------------------------------
   4.  Totals and auxiliary sums needed for the H statistic
   -------------------------------------------------------------------------- */
totals AS (
    SELECT
        COUNT(*)            AS G,          -- number of groups
        SUM(n_i)            AS N,          -- total samples
        SUM(S_i)            AS S_sum,
        SUM(Q_i)            AS Q_sum
    FROM group_stats
),
ss_div_n AS (                           -- Σ (Sᵢ² / nᵢ)
    SELECT SUM( (S_i * S_i) / n_i ) AS value
    FROM group_stats
)

/* --------------------------------------------------------------------------
   5.  Final Kruskal-Wallis H score
   -------------------------------------------------------------------------- */
SELECT
    t.G  AS "total_groups",
    t.N  AS "total_samples",
    /*  H = (N-1) * [ Σ(Sᵢ²/nᵢ) − (ΣSᵢ)² / N ]  /  [ ΣQᵢ − (ΣSᵢ)² / N ]  */
    ( (t.N - 1)
      * (s.value - (t.S_sum * t.S_sum) / t.N)
      / (t.Q_sum - (t.S_sum * t.S_sum) / t.N) )       AS "kruskal_wallis_H"
FROM totals t
CROSS JOIN ss_div_n s
ORDER BY "kruskal_wallis_H" DESC NULLS LAST;