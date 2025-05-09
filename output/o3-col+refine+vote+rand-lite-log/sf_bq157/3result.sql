/*  Welch’s t-test on log10-transformed DRG2 expression
    between TP53–mutant and TP53–wild-type LGG participants           */

WITH lgg_mc3 AS (          -- LGG participants that appear in the mutation table
    SELECT DISTINCT "ParticipantBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE  "Study" = 'LGG'
),
tp53_mut AS (              -- LGG participants carrying a TP53 mutation (FILTER = 'PASS')
    SELECT DISTINCT "ParticipantBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE
    WHERE  "Study"        = 'LGG'
      AND  "Hugo_Symbol"  = 'TP53'
      AND  "FILTER"       = 'PASS'
),
expr AS (                  -- average log10(normalized_count+1) of DRG2 per participant
    SELECT
        e."ParticipantBarcode",
        AVG( LOG(10, e."normalized_count" + 1) ) AS "avg_log_expr"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED.EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED e
    WHERE  e."Study"  = 'LGG'
      AND  e."Symbol" = 'DRG2'
      AND  e."ParticipantBarcode" IN ( SELECT "ParticipantBarcode" FROM lgg_mc3 )
    GROUP BY e."ParticipantBarcode"
),
data AS (                  -- label participants as TP53-mutant (YES/NO)
    SELECT
        x."ParticipantBarcode",
        x."avg_log_expr",
        CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 'YES' ELSE 'NO' END AS "TP53_mut"
    FROM   expr        x
    LEFT  JOIN tp53_mut m
           ON x."ParticipantBarcode" = m."ParticipantBarcode"
),
stats AS (                 -- group-wise summations needed for Welch’s t statistic
    SELECT
        SUM( CASE WHEN "TP53_mut" = 'YES' THEN "avg_log_expr"          END ) AS "Sy",
        SUM( CASE WHEN "TP53_mut" = 'YES' THEN POWER("avg_log_expr",2) END ) AS "Qy",
        COUNT( CASE WHEN "TP53_mut" = 'YES' THEN 1                     END ) AS "Ny",
        SUM( CASE WHEN "TP53_mut" = 'NO'  THEN "avg_log_expr"          END ) AS "Sn",
        SUM( CASE WHEN "TP53_mut" = 'NO'  THEN POWER("avg_log_expr",2) END ) AS "Qn",
        COUNT( CASE WHEN "TP53_mut" = 'NO'  THEN 1                     END ) AS "Nn"
    FROM data
)
SELECT
    "Ny",                             -- number of TP53-mutant participants
    "Nn",                             -- number of TP53-wild-type participants
    "Sy"/"Ny"                                                    AS "avg_y",
    "Sn"/"Nn"                                                    AS "avg_n",
    ("Qy" - POWER("Sy",2)/"Ny")/("Ny"-1)                         AS "var_y",
    ("Qn" - POWER("Sn",2)/"Nn")/("Nn"-1)                         AS "var_n",
    ( ("Sy"/"Ny") - ("Sn"/"Nn") ) /
    SQRT( (("Qy" - POWER("Sy",2)/"Ny")/("Ny"-1)) / "Ny"
         + (("Qn" - POWER("Sn",2)/"Nn")/("Nn"-1)) / "Nn" )       AS "t_score"
FROM stats;