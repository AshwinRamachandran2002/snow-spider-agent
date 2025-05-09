/* Welch T-score for log10-transformed DRG2 expression
   comparing participants WITH vs. WITHOUT a ‘PASS’ TP53 mutation        */

WITH mc3_patients AS (                       -- every participant present in MC3
    SELECT DISTINCT "ParticipantBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
),
expr AS (                                    -- log10(normalized_count + 1) for DRG2
    SELECT  e."ParticipantBarcode",
            LOG(10, e."normalized_count" + 1) AS log_expr   -- LOG(base, value)
    FROM    PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" e
    JOIN    mc3_patients p
          ON p."ParticipantBarcode" = e."ParticipantBarcode"
    WHERE   e."Symbol" = 'DRG2'
),
patient_avg AS (                             -- average expression per participant
    SELECT  "ParticipantBarcode",
            AVG(log_expr) AS avg_expr
    FROM    expr
    GROUP BY "ParticipantBarcode"
),
tp53_patients AS (                           -- participants with a PASS TP53 mutation
    SELECT DISTINCT "ParticipantBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE  "Hugo_Symbol" = 'TP53'
      AND  "FILTER"      = 'PASS'
),
classified AS (                              -- label YES / NO for TP53 mutation
    SELECT  a."ParticipantBarcode",
            a.avg_expr,
            CASE WHEN t."ParticipantBarcode" IS NOT NULL THEN 'YES'
                 ELSE 'NO' END AS mut_status
    FROM    patient_avg a
    LEFT JOIN tp53_patients t
           ON a."ParticipantBarcode" = t."ParticipantBarcode"
),
stats AS (                                   -- per-group count, Σx, Σx²
    SELECT  mut_status,
            COUNT(*)               AS n,
            SUM(avg_expr)          AS sum_x,
            SUM(POWER(avg_expr,2)) AS sum_x2
    FROM    classified
    GROUP BY mut_status
),
pivoted AS (                                 -- single row with both groups’ stats
    SELECT
        MAX(CASE WHEN mut_status='YES' THEN n      END) AS Ny,
        MAX(CASE WHEN mut_status='NO'  THEN n      END) AS Nn,
        MAX(CASE WHEN mut_status='YES' THEN sum_x  END) AS Sy,
        MAX(CASE WHEN mut_status='NO'  THEN sum_x  END) AS Sn,
        MAX(CASE WHEN mut_status='YES' THEN sum_x2 END) AS Qy,
        MAX(CASE WHEN mut_status='NO'  THEN sum_x2 END) AS Qn
    FROM   stats
),
final AS (                                   -- means, variances, Welch T-score
    SELECT
        Ny,
        Nn,
        Sy / Ny                                            AS avg_y,
        Sn / Nn                                            AS avg_n,
        (Qy - (Sy*Sy)/Ny)/(Ny-1)                           AS var_y,
        (Qn - (Sn*Sn)/Nn)/(Nn-1)                           AS var_n
    FROM   pivoted
)
SELECT
    Ny,
    Nn,
    avg_y,
    avg_n,
    (avg_y - avg_n) / SQRT( (var_y / Ny) + (var_n / Nn) )  AS tscore
FROM   final;