/*--------------------------------------------------------------
  Predict KIRP clinical_stage from MT-CO{1-3} RNA-seq expression
--------------------------------------------------------------*/
WITH kirp_cases AS (                     -- eligible patients
    SELECT
        c."case_barcode",
        c."clinical_stage"
    FROM TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL        c
    WHERE c."project_short_name" = 'TCGA-KIRP'
      AND c."clinical_stage"   IS NOT NULL
),
kirp_expr AS (                           -- expression rows of interest
    SELECT
        r."case_barcode",
        r."gene_name",
        r."HTSeq__FPKM_UQ"
    FROM TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION r
    WHERE r."project_short_name" = 'TCGA-KIRP'
      AND r."gene_name" IN ('MT-CO1','MT-CO2','MT-CO3')
),
per_patient AS (                         -- one row / patient with 3 genes
    SELECT
        k."case_barcode",
        k."clinical_stage",
        AVG(CASE WHEN e."gene_name" = 'MT-CO1' THEN e."HTSeq__FPKM_UQ" END) AS "MT_CO1",
        AVG(CASE WHEN e."gene_name" = 'MT-CO2' THEN e."HTSeq__FPKM_UQ" END) AS "MT_CO2",
        AVG(CASE WHEN e."gene_name" = 'MT-CO3' THEN e."HTSeq__FPKM_UQ" END) AS "MT_CO3"
    FROM kirp_cases k
    JOIN kirp_expr   e ON k."case_barcode" = e."case_barcode"
    GROUP BY k."case_barcode", k."clinical_stage"
),
bucketed AS (                            -- deterministic 0-9 bucket
    SELECT
        p.*,
        ABS( MOD( HASH(p."case_barcode"), 10) ) AS "bucket"
    FROM per_patient p
),
stage_means AS (                         -- training-set stage averages
    SELECT
        "clinical_stage",
        AVG("MT_CO1") AS "AVG_CO1",
        AVG("MT_CO2") AS "AVG_CO2",
        AVG("MT_CO3") AS "AVG_CO3"
    FROM bucketed
    WHERE "bucket" < 9                   -- 90 % TRAIN (buckets 0-8)
    GROUP BY "clinical_stage"
),
distances AS (                           -- distance test-patient → stage
    SELECT
        b."case_barcode",
        s."clinical_stage"                              AS "pred_stage",
        SQRT( POWER( COALESCE(b."MT_CO1",0) - COALESCE(s."AVG_CO1",0), 2) +
              POWER( COALESCE(b."MT_CO2",0) - COALESCE(s."AVG_CO2",0), 2) +
              POWER( COALESCE(b."MT_CO3",0) - COALESCE(s."AVG_CO3",0), 2) ) AS "dist",
        ROW_NUMBER() OVER (PARTITION BY b."case_barcode"
                           ORDER BY
                                 SQRT( POWER( COALESCE(b."MT_CO1",0) - COALESCE(s."AVG_CO1",0), 2) +
                                       POWER( COALESCE(b."MT_CO2",0) - COALESCE(s."AVG_CO2",0), 2) +
                                       POWER( COALESCE(b."MT_CO3",0) - COALESCE(s."AVG_CO3",0), 2) )
                           ) AS rn
    FROM bucketed   b
    CROSS JOIN stage_means s
    WHERE b."bucket" = 9                 -- 10 % TEST (bucket 9)
)
SELECT
    "case_barcode",
    "pred_stage" AS "predicted_clinical_stage"
FROM   distances
WHERE  rn = 1                            -- nearest stage only
ORDER  BY "case_barcode";