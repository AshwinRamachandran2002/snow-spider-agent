/*---------------------------------------------------------------
  Welch’s t-test for DRG2 expression in TCGA-LGG participants
  with vs. without PASS-filtered TP53 mutations
----------------------------------------------------------------*/

WITH lgg_participants AS (            -- LGG cases present in MC3
    SELECT DISTINCT "ParticipantBarcode"
    FROM "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study"  = 'LGG'
      AND "FILTER" = 'PASS'
),
tp53_mut AS (                         -- LGG patients harbouring TP53 mutation
    SELECT DISTINCT "ParticipantBarcode"
    FROM "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study"       = 'LGG'
      AND "FILTER"      = 'PASS'
      AND "Hugo_Symbol" = 'TP53'
),
patient_expr AS (                     -- mean log10( DRG2 + 1 ) per patient
    SELECT
        e."ParticipantBarcode",
        AVG( LOG(10, e."normalized_count" + 1) ) AS avg_log_expr    -- use LOG(base, value)
    FROM "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" e
    JOIN lgg_participants lp
      ON lp."ParticipantBarcode" = e."ParticipantBarcode"
    WHERE e."Symbol" = 'DRG2'
    GROUP BY e."ParticipantBarcode"
),
flagged AS (                          -- label patients YES / NO for TP53 mut
    SELECT
        p."ParticipantBarcode",
        p.avg_log_expr,
        CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 'YES' ELSE 'NO' END AS tp53_mut_flag
    FROM patient_expr p
    LEFT JOIN tp53_mut m
           ON m."ParticipantBarcode" = p."ParticipantBarcode"
),
summed AS (                            -- S = Σg , Q = Σg² for each group
    SELECT
        tp53_mut_flag,
        COUNT(*)::FLOAT                           AS N,
        SUM( avg_log_expr )::FLOAT                AS S,
        SUM( POWER( avg_log_expr , 2 ) )::FLOAT   AS Q
    FROM flagged
    GROUP BY tp53_mut_flag
),
pivot AS (                             -- put group statistics on single row
    SELECT
        MAX( CASE WHEN tp53_mut_flag = 'YES' THEN N END ) AS Ny ,
        MAX( CASE WHEN tp53_mut_flag = 'NO'  THEN N END ) AS Nn ,
        MAX( CASE WHEN tp53_mut_flag = 'YES' THEN S END ) AS Sy ,
        MAX( CASE WHEN tp53_mut_flag = 'NO'  THEN S END ) AS Sn ,
        MAX( CASE WHEN tp53_mut_flag = 'YES' THEN Q END ) AS Qy ,
        MAX( CASE WHEN tp53_mut_flag = 'NO'  THEN Q END ) AS Qn
    FROM summed
)

SELECT
    Ny,
    Nn,
    Sy / Ny                                                        AS avg_y ,
    Sn / Nn                                                        AS avg_n ,
    ( (Sy / Ny) - (Sn / Nn) ) /                                    /* Welch’s T-score */
    SQRT(  ( (Qy - POWER(Sy,2)/Ny) / (Ny - 1) ) / Ny
         + ( (Qn - POWER(Sn,2)/Nn) / (Nn - 1) ) / Nn )             AS tscore
FROM pivot;