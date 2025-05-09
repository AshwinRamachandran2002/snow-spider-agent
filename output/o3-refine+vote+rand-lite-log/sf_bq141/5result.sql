/* ---------------------------------------------------------------
   Predict TCGA‑KIRP clinical stage from three MT‑CO gene expressions
   ---------------------------------------------------------------*/
WITH kirp_patients AS (   -- 1)  keep only KIRP cases that have a stage
    SELECT DISTINCT
           "case_barcode",
           "clinical_stage"
    FROM   TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0."CLINICAL"
    WHERE  "disease_code"   = 'KIRP'
      AND  "clinical_stage" IS NOT NULL
), gene_expr AS (         -- 2)  gather expression for MT‑CO1/2/3
    SELECT
           r."case_barcode",
           r."gene_name",
           AVG(r."HTSeq__FPKM_UQ") AS expr
    FROM   TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."RNASEQ_GENE_EXPRESSION" r
           JOIN kirp_patients k
             ON r."case_barcode" = k."case_barcode"
    WHERE  r."gene_name" IN ('MT-CO1','MT-CO2','MT-CO3')
    GROUP  BY r."case_barcode", r."gene_name"
), expr_wide AS (         -- 3)  pivot to one row per patient
    SELECT
           "case_barcode",
           MAX(CASE WHEN "gene_name"='MT-CO1' THEN expr END) AS mtco1,
           MAX(CASE WHEN "gene_name"='MT-CO2' THEN expr END) AS mtco2,
           MAX(CASE WHEN "gene_name"='MT-CO3' THEN expr END) AS mtco3
    FROM   gene_expr
    GROUP  BY "case_barcode"
), data AS (              -- 4)  merge + deterministic 90‑10 split
    SELECT
           k."case_barcode",
           k."clinical_stage",
           COALESCE(e.mtco1, 0) AS mtco1,
           COALESCE(e.mtco2, 0) AS mtco2,
           COALESCE(e.mtco3, 0) AS mtco3,
           CASE
               WHEN ABS(HASH(k."case_barcode")) % 10 < 9
               THEN 'TRAIN' ELSE 'TEST'
           END AS set_type
    FROM   kirp_patients k
           LEFT JOIN expr_wide e USING ("case_barcode")
), centroids AS (         -- 5)  mean expression for each stage (training)
    SELECT
           "clinical_stage",
           AVG(mtco1) AS c_mtco1,
           AVG(mtco2) AS c_mtco2,
           AVG(mtco3) AS c_mtco3
    FROM   data
    WHERE  set_type = 'TRAIN'
    GROUP  BY "clinical_stage"
), distances AS (         -- 6)  distance of each TEST case to every centroid
    SELECT
           d."case_barcode",
           c."clinical_stage"                                                  AS stage_candidate,
           SQRT( POWER(d.mtco1 - c.c_mtco1, 2) +
                 POWER(d.mtco2 - c.c_mtco2, 2) +
                 POWER(d.mtco3 - c.c_mtco3, 2) )                                AS dist
    FROM   data d
           JOIN centroids c
             ON d.set_type = 'TEST'
), ranked AS (            -- 7)  keep nearest centroid per patient
    SELECT
           "case_barcode",
           stage_candidate            AS predicted_stage,
           ROW_NUMBER() OVER (PARTITION BY "case_barcode"
                              ORDER BY dist) AS rn
    FROM   distances
)
-- 8)  final prediction list
SELECT
       "case_barcode",
       predicted_stage   AS "predicted_clinical_stage"
FROM   ranked
WHERE  rn = 1
ORDER  BY "case_barcode";