/*  Kruskal‑Wallis H for IGF2 expression across ICD‑O‑3 histology
    in LGG patients                                               */

WITH expr AS (   --------------------------------------------------
  /* Gene‑expression: LGG, IGF2, log10(normalized_count + 1)
     averaged per participant                                     */
  SELECT
      "ParticipantBarcode",
      AVG( LOG(10 , "normalized_count" + 1) )          AS expr_value
  FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED
  WHERE  "Study" = 'LGG'
    AND  "Symbol" = 'IGF2'
    AND  "normalized_count" IS NOT NULL
  GROUP  BY "ParticipantBarcode"
),
clin AS (         --------------------------------------------------
  /* ICD‑O‑3 histology, drop values fully enclosed in brackets     */
  SELECT
      "bcr_patient_barcode"   AS "ParticipantBarcode",
      "icd_o_3_histology"     AS histology
  FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED
  WHERE  "icd_o_3_histology" IS NOT NULL
    AND  NOT REGEXP_LIKE("icd_o_3_histology", '^\[.*\]$')
),
merged AS (       --------------------------------------------------
  /* Participants with both expression and histology               */
  SELECT e."ParticipantBarcode",
         c.histology,
         e.expr_value
  FROM   expr  e
  JOIN   clin  c
         ON e."ParticipantBarcode" = c."ParticipantBarcode"
),
valid_groups AS ( --------------------------------------------------
  /* Keep histology groups with > 1 patient                        */
  SELECT  histology
  FROM    merged
  GROUP   BY histology
  HAVING  COUNT(*) > 1
),
filtered AS (     --------------------------------------------------
  SELECT m.*
  FROM   merged m
  JOIN   valid_groups g USING (histology)
),
ranked AS (       --------------------------------------------------
  /* First rank and tie count                                      */
  SELECT
      *,
      RANK()   OVER (ORDER BY expr_value)               AS r_first,
      COUNT(*) OVER (PARTITION BY expr_value)           AS tie_cnt
  FROM filtered
),
ranks AS (        --------------------------------------------------
  /* Average rank for ties                                         */
  SELECT
      "ParticipantBarcode",
      histology,
      expr_value,
      r_first + (tie_cnt - 1) / 2.0                     AS avg_rank
  FROM ranked
),
grp_stats AS (    --------------------------------------------------
  /* n_i, S_i, Q_i per histology                                  */
  SELECT
      histology,
      COUNT(*)                    AS n_i,
      SUM(avg_rank)               AS S_i,
      SUM(POWER(avg_rank, 2))     AS Q_i
  FROM ranks
  GROUP BY histology
),
totals AS (       --------------------------------------------------
  SELECT
      SUM(n_i)                              AS N,
      SUM(S_i)                              AS sum_S,
      SUM(Q_i)                              AS sum_Q,
      SUM(POWER(S_i, 2) / n_i)              AS sum_S_sq_over_n,
      COUNT(*)                              AS total_groups
  FROM grp_stats
),
kw AS (           --------------------------------------------------
  /* Kruskal‑Wallis H                                              */
  SELECT
      total_groups,
      N                                 AS total_samples,
      ROUND(
        ((N - 1) *
         (sum_S_sq_over_n - POWER(sum_S, 2) / N)) /
        NULLIF((sum_Q - POWER(sum_S, 2) / N), 0),
        4)                              AS H_score
  FROM totals
)
SELECT  total_groups,
        total_samples,
        H_score
FROM    kw
ORDER BY H_score DESC NULLS LAST;