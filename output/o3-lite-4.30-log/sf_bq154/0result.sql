/* ──────────────────────────────────────────────────────────────────────────────
   Kruskal–Wallis H‑test for IGF2 expression (LGG) grouped by ICD‑O‑3 histology
   ─────────────────────────────────────────────────────────────────────────── */

WITH expr AS (  -- per‑patient log10‑transformed IGF2 expression
  SELECT
    "ParticipantBarcode",
    AVG( LOG(10, "normalized_count" + 1) )        AS "igf2_log_expr"
  FROM "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"
       ."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
  WHERE "Study"       = 'LGG'
    AND "Symbol"      = 'IGF2'
    AND "normalized_count" IS NOT NULL
  GROUP BY "ParticipantBarcode"
),

base AS (        -- attach histology and discard bracketed codes
  SELECT
    e."ParticipantBarcode",
    c."icd_o_3_histology",
    e."igf2_log_expr"
  FROM expr e
  JOIN "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"
       ."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED" c
    ON e."ParticipantBarcode" = c."bcr_patient_barcode"
  WHERE c."icd_o_3_histology" NOT ILIKE '\[%\]'
),

ranked AS (      -- mid‑rank for ties
  SELECT
    *,
    RANK()  OVER (ORDER BY "igf2_log_expr")       AS r_min,
    COUNT(*) OVER (PARTITION BY "igf2_log_expr")  AS dup_cnt
  FROM base
),

with_ranks AS (
  SELECT
    "ParticipantBarcode",
    "icd_o_3_histology",
    r_min + (dup_cnt - 1) / 2.0                   AS avg_rank
  FROM ranked
),

grp AS (         -- S_i and Q_i per histology; keep groups with >1 patient
  SELECT
    "icd_o_3_histology"       AS g,
    COUNT(*)                  AS n_i,
    SUM(avg_rank)             AS S_i,
    SUM(POWER(avg_rank,2))    AS Q_i
  FROM with_ranks
  GROUP BY g
  HAVING COUNT(*) > 1
),

tot AS (         -- global totals
  SELECT
    SUM(n_i)  AS N,
    SUM(S_i)  AS S_tot,
    SUM(Q_i)  AS Q_tot
  FROM grp
)

/* final output */
SELECT
  (SELECT COUNT(*) FROM grp)                                         AS total_groups,
  (SELECT N FROM tot)                                                AS total_samples,
  ROUND(
    (
      ((SELECT N FROM tot) - 1) *
      ( SUM( POWER(S_i,2) / n_i ) -
        POWER((SELECT S_tot FROM tot), 2) / (SELECT N FROM tot) )
    ) /
    (
      (SELECT Q_tot FROM tot) -
      POWER((SELECT S_tot FROM tot), 2) / (SELECT N FROM tot)
    )
  , 4)                                                               AS kruskal_wallis_h_score
FROM grp;