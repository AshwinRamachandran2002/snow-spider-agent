WITH
/*--------------------------------------------------------------------
1. LGG tumour samples present in the mutation table
--------------------------------------------------------------------*/
lgg_samples AS (
    SELECT DISTINCT "ParticipantBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE  "Study" = 'LGG'
),
/*--------------------------------------------------------------------
2. LGG patients carrying a PASS-filtered TP53 mutation
--------------------------------------------------------------------*/
tp53_mut AS (
    SELECT DISTINCT "ParticipantBarcode"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE  "Study"       = 'LGG'
      AND  "Hugo_Symbol" = 'TP53'
      AND  "FILTER"      = 'PASS'
),
/*--------------------------------------------------------------------
3. Per-patient average log10( DRG2 expression + 1 ),
   using only samples whose participant appears in lgg_samples
   (log10 computed as LN(x)/LN(10) to avoid LOG10() incompatibility)
--------------------------------------------------------------------*/
per_patient AS (
    SELECT
        ge."ParticipantBarcode",
        AVG( LN( ge."normalized_count" + 1 ) / LN(10) ) AS "avg_log10_expr"
    FROM   PANCANCER_ATLAS_1.PANCANCER_ATLAS_FILTERED."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED" ge
    JOIN   lgg_samples ls
      ON   ge."ParticipantBarcode" = ls."ParticipantBarcode"
    WHERE  ge."Study"  = 'LGG'
      AND  ge."Symbol" = 'DRG2'
    GROUP BY ge."ParticipantBarcode"
),
/*--------------------------------------------------------------------
4. Label each patient by TP53-mutation status
--------------------------------------------------------------------*/
labelled AS (
    SELECT
        p."ParticipantBarcode",
        p."avg_log10_expr",
        CASE WHEN m."ParticipantBarcode" IS NOT NULL THEN 'YES' ELSE 'NO' END AS "TP53_mut"
    FROM   per_patient p
    LEFT JOIN tp53_mut m
      ON   p."ParticipantBarcode" = m."ParticipantBarcode"
),
/*--------------------------------------------------------------------
5. Aggregate counts and sums required for Welch’s T-test
--------------------------------------------------------------------*/
agg AS (
    SELECT
        "TP53_mut",
        COUNT(*)                            AS "N",
        SUM( "avg_log10_expr" )             AS "S",
        SUM( POWER( "avg_log10_expr", 2 ) ) AS "Q"
    FROM   labelled
    GROUP BY "TP53_mut"
)
/*--------------------------------------------------------------------
6. Final T-score comparing TP53-mutant (YES) vs wild-type (NO)
--------------------------------------------------------------------*/
SELECT
    a."N"                                            AS "Ny",
    b."N"                                            AS "Nn",
    a."S" / a."N"                                    AS "avg_y",
    b."S" / b."N"                                    AS "avg_n",
    ( (a."S" / a."N") - (b."S" / b."N") ) /
    SQRT(
          ( (a."Q" - POWER(a."S", 2) / a."N") / (a."N" - 1) ) / a."N"
        + ( (b."Q" - POWER(b."S", 2) / b."N") / (b."N" - 1) ) / b."N"
    )                                                AS "t_score"
FROM   agg a
JOIN   agg b
  ON   a."TP53_mut" = 'YES'
 AND   b."TP53_mut" = 'NO';