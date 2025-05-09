/*  -------- 1.  PATIENT⇥LEVEL EXPRESSION VECTORS ---------------------------- */
WITH clinical_filtered AS (          -- KIRP cases that have a valid stage
    SELECT DISTINCT 
           "case_barcode",
           "clinical_stage"
    FROM   TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0.CLINICAL
    WHERE  "disease_code"      = 'KIRP'
      AND  "clinical_stage" IS NOT NULL
),  

expr_filtered AS (                   -- keep only the 3 requested genes
    SELECT 
           "case_barcode",
           "gene_name",
           "HTSeq__FPKM_UQ"
    FROM   TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0.RNASEQ_GENE_EXPRESSION
    WHERE  "project_short_name" = 'TCGA-KIRP'
      AND  "gene_name"          IN ('MT-CO3','MT-CO1','MT-CO2')
),  

patient_expr AS (                    -- pivot 3‑gene vector per patient
    SELECT 
           c."case_barcode",
           c."clinical_stage",
           MAX( CASE WHEN e."gene_name"='MT-CO1' THEN e."HTSeq__FPKM_UQ" END ) AS "MT_CO1",
           MAX( CASE WHEN e."gene_name"='MT-CO2' THEN e."HTSeq__FPKM_UQ" END ) AS "MT_CO2",
           MAX( CASE WHEN e."gene_name"='MT-CO3' THEN e."HTSeq__FPKM_UQ" END ) AS "MT_CO3"
    FROM   clinical_filtered c
    JOIN   expr_filtered      e  USING ("case_barcode")
    GROUP  BY c."case_barcode", c."clinical_stage"
),  

patient_split AS (                   -- deterministic 90/10 split via HASH()
    SELECT 
           p.*,
           ABS( HASH(p."case_barcode") )                       AS "hash_val",
           CASE WHEN MOD( ABS( HASH(p."case_barcode") ), 10) < 9 
                THEN 'TRAIN' ELSE 'TEST' END                  AS "split_flag"
    FROM   patient_expr p
),  

train_set AS ( SELECT * FROM patient_split WHERE "split_flag" = 'TRAIN' ),
test_set  AS ( SELECT * FROM patient_split WHERE "split_flag" = 'TEST'  ),

/*  -------- 2.  STAGE–SPECIFIC AVERAGES (TRAIN) ----------------------------- */
stage_avg AS (
    SELECT 
           "clinical_stage",
           AVG("MT_CO1") AS "avg_mt_co1",
           AVG("MT_CO2") AS "avg_mt_co2",
           AVG("MT_CO3") AS "avg_mt_co3"
    FROM   train_set
    GROUP  BY "clinical_stage"
),

/*  -------- 3.  DISTANCES & PREDICTIONS (TEST) ------------------------------ */
distances AS (
    SELECT 
           t."case_barcode",
           s."clinical_stage"                                               AS "candidate_stage",
           SQRT(  POWER(t."MT_CO1" - s."avg_mt_co1",2) 
                + POWER(t."MT_CO2" - s."avg_mt_co2",2) 
                + POWER(t."MT_CO3" - s."avg_mt_co3",2) )                    AS "euclid_dist"
    FROM   test_set  t
    CROSS  JOIN stage_avg s
)

SELECT 
       "case_barcode",
       FIRST_VALUE("candidate_stage")      -- stage with smallest distance
           OVER (PARTITION BY "case_barcode" 
                 ORDER BY "euclid_dist")    AS "predicted_clinical_stage"
FROM   distances
QUALIFY ROW_NUMBER() OVER (PARTITION BY "case_barcode" 
                           ORDER BY "euclid_dist") = 1
ORDER  BY "case_barcode";