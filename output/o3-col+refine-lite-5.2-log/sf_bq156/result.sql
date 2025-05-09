WITH tp53_mutated AS (   -- LGG participants with at least one ‘PASS’ TP53 mutation
    SELECT DISTINCT "ParticipantBarcode"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Hugo_Symbol" = 'TP53'
      AND "Study"       = 'LGG'
      AND "FILTER"      = 'PASS'
),
expr_per_patient AS (    -- Mean log10‑transformed DRG2 expression per participant
    SELECT
        "ParticipantBarcode",
        AVG( LOG(10, "normalized_count" + 1) ) AS "expr"
    FROM PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
    WHERE "Study"  = 'LGG'
      AND "Symbol" = 'DRG2'
    GROUP BY "ParticipantBarcode"
),
expr_with_status AS (    -- Label participants as Mutated vs NonMutated
    SELECT
        e."ParticipantBarcode",
        CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 'Mutated'
             ELSE 'NonMutated' END           AS "TP53_status",
        e."expr"
    FROM expr_per_patient e
    LEFT JOIN tp53_mutated m
           ON e."ParticipantBarcode" = m."ParticipantBarcode"
),
stats AS (               -- N, mean, sample variance for each group
    SELECT
        "TP53_status",
        COUNT(*)         AS "n",
        AVG("expr")      AS "mean",
        VAR_SAMP("expr") AS "variance"
    FROM expr_with_status
    GROUP BY "TP53_status"
),
final AS (               -- Keep only valid groups (≥10 samples, non‑zero variance)
    SELECT
        mut."n"        AS "n_mut",
        non."n"        AS "n_non",
        mut."mean"     AS "mean_mut",
        non."mean"     AS "mean_non",
        mut."variance" AS "var_mut",
        non."variance" AS "var_non"
    FROM stats mut
    JOIN stats non
      ON mut."TP53_status"  = 'Mutated'
     AND non."TP53_status" = 'NonMutated'
    WHERE mut."n" >= 10
      AND non."n" >= 10
      AND mut."variance"  > 0
      AND non."variance" > 0
)
SELECT
    ROUND(
        ( "mean_mut" - "mean_non" )
        /
        SQRT( ("var_mut" / "n_mut") + ("var_non" / "n_non") ),
        2
    ) AS "t_score"
FROM final;