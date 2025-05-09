WITH kirp_clin AS (                 -- KIRP patients with a known clinical stage
    SELECT  "case_barcode",
            "clinical_stage"
    FROM    TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL
    WHERE   "disease_code"  = 'KIRP'
      AND   "clinical_stage" IS NOT NULL
), kirp_expr AS (                   -- RNA-seq expression for the three mitochondrial genes
    SELECT  "case_barcode",
            "gene_name",
            "HTSeq__FPKM_UQ"
    FROM    TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION
    WHERE   "project_short_name" = 'TCGA-KIRP'
      AND   "gene_name" IN ('MT-CO1','MT-CO2','MT-CO3')
), patient_vec AS (                 -- pivot to one row per patient
    SELECT  c."case_barcode",
            c."clinical_stage",
            MAX(CASE WHEN e."gene_name" = 'MT-CO1' THEN e."HTSeq__FPKM_UQ" END) AS "MT_CO1",
            MAX(CASE WHEN e."gene_name" = 'MT-CO2' THEN e."HTSeq__FPKM_UQ" END) AS "MT_CO2",
            MAX(CASE WHEN e."gene_name" = 'MT-CO3' THEN e."HTSeq__FPKM_UQ" END) AS "MT_CO3"
    FROM    kirp_clin      c
    JOIN    kirp_expr      e  ON c."case_barcode" = e."case_barcode"
    GROUP BY c."case_barcode", c."clinical_stage"
),                                      -- 90 % train / 10 % test split by hash of barcode
train_stage_avg AS (
    SELECT  "clinical_stage",
            AVG("MT_CO1") AS "avg_MT_CO1",
            AVG("MT_CO2") AS "avg_MT_CO2",
            AVG("MT_CO3") AS "avg_MT_CO3"
    FROM    patient_vec
    WHERE   MOD(ABS(HASH("case_barcode")),10) < 9          -- training 90 %
    GROUP BY "clinical_stage"
), test_vec AS (
    SELECT  "case_barcode",
            "MT_CO1",
            "MT_CO2",
            "MT_CO3"
    FROM    patient_vec
    WHERE   MOD(ABS(HASH("case_barcode")),10) >= 9         -- test 10 %
), distances AS (                                           -- distance of every test patient to each stage centroid
    SELECT  t."case_barcode",
            s."clinical_stage",
            SQRT( POWER(t."MT_CO1" - s."avg_MT_CO1", 2)
                + POWER(t."MT_CO2" - s."avg_MT_CO2", 2)
                + POWER(t."MT_CO3" - s."avg_MT_CO3", 2) )   AS "eucl_distance"
    FROM    test_vec       t
    CROSS JOIN train_stage_avg s
), ranked AS (                                              -- pick closest stage for every patient
    SELECT  d.*,
            ROW_NUMBER() OVER (PARTITION BY d."case_barcode"
                               ORDER BY CASE WHEN d."eucl_distance" IS NULL THEN 1 ELSE 0 END,
                                        d."eucl_distance") AS rn
    FROM    distances d
)
SELECT  "case_barcode",
        "clinical_stage" AS "predicted_clinical_stage"
FROM    ranked
WHERE   rn = 1
ORDER BY "case_barcode";