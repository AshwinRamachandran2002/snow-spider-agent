WITH mutation_samples AS (   -- every LGG tumour sample present in MC3
    SELECT DISTINCT "Tumor_SampleBarcode"
    FROM "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study" = 'LGG'
),
expr AS (                     -- per‑patient mean log10(DRG2+1) expression
    SELECT
        "ParticipantBarcode",
        AVG( LOG(10, "normalized_count" + 1) ) AS avg_log_dn
    FROM "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."EBPP_ADJUSTPANCAN_ILLUMINAHISEQ_RNASEQV2_GENEXP_FILTERED"
    WHERE "Study"      = 'LGG'
      AND "Symbol"     = 'DRG2'
      AND "SampleBarcode" IN (SELECT "Tumor_SampleBarcode" FROM mutation_samples)
    GROUP BY "ParticipantBarcode"
),
tp53_mut AS (                 -- LGG patients harbouring a PASS TP53 mutation
    SELECT DISTINCT "ParticipantBarcode"
    FROM "PANCANCER_ATLAS_1"."PANCANCER_ATLAS_FILTERED"."MC3_MAF_V5_ONE_PER_TUMOR_SAMPLE"
    WHERE "Study"        = 'LGG'
      AND "Hugo_Symbol"  = 'TP53'
      AND "FILTER"       = 'PASS'
),
base AS (                     -- expression table with mutation label
    SELECT
        e."ParticipantBarcode",
        e.avg_log_dn,
        CASE WHEN t."ParticipantBarcode" IS NULL THEN 'NO' ELSE 'YES' END AS TP53_MUT
    FROM expr e
    LEFT JOIN tp53_mut t
      ON e."ParticipantBarcode" = t."ParticipantBarcode"
),
agg AS (                      -- group statistics needed for Welch’s t‑test
    SELECT
        TP53_MUT,
        COUNT(*)             AS N,
        AVG(avg_log_dn)      AS mean,
        VAR_SAMP(avg_log_dn) AS var
    FROM base
    GROUP BY TP53_MUT
),
calc AS (
    SELECT
        (SELECT mean FROM agg WHERE TP53_MUT = 'YES') AS mean_y,
        (SELECT mean FROM agg WHERE TP53_MUT = 'NO' ) AS mean_n,
        (SELECT var  FROM agg WHERE TP53_MUT = 'YES') AS var_y,
        (SELECT var  FROM agg WHERE TP53_MUT = 'NO' ) AS var_n,
        (SELECT N    FROM agg WHERE TP53_MUT = 'YES') AS ny,
        (SELECT N    FROM agg WHERE TP53_MUT = 'NO' ) AS nn
)
SELECT
    ROUND( (mean_y - mean_n) / SQRT( var_y/ny + var_n/nn ), 4 ) AS t_score
FROM calc;