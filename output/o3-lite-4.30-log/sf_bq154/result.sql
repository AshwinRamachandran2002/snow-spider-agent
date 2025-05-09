WITH expr AS (   -- log10‑transformed IGF2 expression for each LGG sample
    SELECT  "ParticipantBarcode"                         AS "participant",
            LN("normalized_count" + 1) / LN(10)          AS "expr_val"
    FROM    "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"
            ."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
    WHERE   "Study"  = 'LGG'
      AND   "Symbol" = 'IGF2'
      AND   "normalized_count" IS NOT NULL
),
avg_expr AS (    -- average expression per participant
    SELECT  "participant",
            AVG("expr_val")                             AS "avg_expr"
    FROM    expr
    GROUP BY "participant"
),
clin AS (        -- ICD‑O‑3 histology for LGG participants
    SELECT  "bcr_patient_barcode"                       AS "participant",
            "icd_o_3_histology"                         AS "hist"
    FROM    "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"
            ."CLINICAL_PANCAN_PATIENT_WITH_FOLLOWUP_FILTERED"
    WHERE   "acronym" = 'LGG'
),
joined AS (      -- join expression with clinical data and clean histology
    SELECT  a."participant",
            a."avg_expr",
            c."hist"
    FROM    avg_expr a
    JOIN    clin     c  ON a."participant" = c."participant"
    WHERE   c."hist" IS NOT NULL
      AND   NOT REGEXP_LIKE(c."hist", '^\\[.*\\]$')
),
ranked AS (      -- average rank (ties get mean rank)
    SELECT  "participant",
            "hist",
            r + (t - 1) / 2.0                           AS "avg_rank"
    FROM   (
        SELECT  j.*,
                RANK()  OVER (ORDER BY j."avg_expr")         AS r,
                COUNT(*) OVER (PARTITION BY j."avg_expr")    AS t
        FROM    joined j
    ) s
),
agg AS (         -- S_i, Q_i, n_i   (discard groups with single sample)
    SELECT  "hist",
            COUNT(*)                                    AS "n_i",
            SUM("avg_rank")                             AS "S_i",
            SUM("avg_rank" * "avg_rank")                AS "Q_i"
    FROM    ranked
    GROUP BY "hist"
    HAVING COUNT(*) > 1
),
tot AS (         -- grand totals
    SELECT  SUM("n_i")                                 AS "N_all",
            SUM("S_i")                                 AS "S_total",
            SUM("Q_i")                                 AS "Q_total",
            SUM("S_i" * "S_i" / "n_i")                 AS "S2_over_n"
    FROM    agg
),
calc AS (        -- numerator and denominator for H statistic
    SELECT  (("N_all" - 1) * ("S2_over_n" - ("S_total" * "S_total") / "N_all"))
                AS num,
            ("Q_total" - ("S_total" * "S_total") / "N_all")    AS denom,
            "N_all"                                            AS total_samples,
            (SELECT COUNT(*) FROM agg)                         AS total_groups
    FROM    tot
)
SELECT  TO_NUMBER(total_groups)                              AS total_groups,
        TO_NUMBER(total_samples)                             AS total_samples,
        ROUND(num / denom, 4)                                AS kruskal_wallis_h_score
FROM    calc
WHERE   denom <> 0
ORDER BY kruskal_wallis_h_score DESC NULLS LAST;