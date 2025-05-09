/*------------------------------------------------------------
  - Pull every KIRP case that carries a non-null clinical_stage
    from ANY of the three clinical tables.
  - Collect MT-CO1, MT-CO2, MT-CO3 expression (FPKM-UQ) and
    pivot them into columns (missing values → 0).
  - Create a reproducible 90 / 10 split with Snowflake HASH().
  - Compute stage–centroid means from training data.
  - For each test case choose the nearest centroid (Euclidean)
    and report the predicted stage.
------------------------------------------------------------*/
WITH clinical_union AS (          -- KIRP cases + stage
    SELECT DISTINCT "case_barcode", "clinical_stage"
    FROM   TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0."CLINICAL"
    WHERE  "disease_code" = 'KIRP'  AND "clinical_stage" IS NOT NULL

    UNION ALL
    SELECT DISTINCT "case_barcode", "clinical_stage"
    FROM   TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0."CLINICAL_V1"
    WHERE  "disease_code" = 'KIRP'  AND "clinical_stage" IS NOT NULL

    UNION ALL
    SELECT DISTINCT "case_barcode", "clinical_stage"
    FROM   TCGA_HG38_DATA_V0.TCGA_BIOCLIN_V0."CLINICAL_V1_1"
    WHERE  "disease_code" = 'KIRP'  AND "clinical_stage" IS NOT NULL
),

expr_raw AS (                     -- raw rows for the three genes
    SELECT  "case_barcode",
            "gene_name",
            AVG("HTSeq__FPKM_UQ") AS "fpkm_uq"
    FROM    TCGA_HG38_DATA_V0.TCGA_HG38_DATA_V0."RNASEQ_GENE_EXPRESSION"
    WHERE   "project_short_name" = 'TCGA-KIRP'
      AND   "gene_name" IN ('MT-CO1','MT-CO2','MT-CO3')
    GROUP BY "case_barcode", "gene_name"
),

expr AS (                         -- pivot → one row per case
    SELECT  "case_barcode",
            COALESCE(MAX(CASE WHEN "gene_name"='MT-CO1' THEN "fpkm_uq" END),0) AS "MT_CO1",
            COALESCE(MAX(CASE WHEN "gene_name"='MT-CO2' THEN "fpkm_uq" END),0) AS "MT_CO2",
            COALESCE(MAX(CASE WHEN "gene_name"='MT-CO3' THEN "fpkm_uq" END),0) AS "MT_CO3"
    FROM    expr_raw
    GROUP BY "case_barcode"
),

data AS (                         -- combine clinical + expr, derive bucket
    SELECT  c."case_barcode",
            c."clinical_stage",
            e."MT_CO1",
            e."MT_CO2",
            e."MT_CO3",
            MOD(ABS(HASH(c."case_barcode")),10) AS "bucket"
    FROM    clinical_union c
    JOIN    expr            e  ON c."case_barcode" = e."case_barcode"
),

train AS ( SELECT * FROM data WHERE "bucket" < 9 ),   -- 90 %
test  AS ( SELECT * FROM data WHERE "bucket" >= 9 ),  -- 10 %

stage_centroid AS (               -- mean expression per stage (train)
    SELECT  "clinical_stage",
            AVG("MT_CO1") AS "AVG_CO1",
            AVG("MT_CO2") AS "AVG_CO2",
            AVG("MT_CO3") AS "AVG_CO3"
    FROM    train
    GROUP BY "clinical_stage"
),

distance_calc AS (                -- distance of every test case to each centroid
    SELECT  t."case_barcode",
            sc."clinical_stage"                                    AS "candidate_stage",
            SQRT(  POWER(t."MT_CO1" - sc."AVG_CO1",2)
                 + POWER(t."MT_CO2" - sc."AVG_CO2",2)
                 + POWER(t."MT_CO3" - sc."AVG_CO3",2) )            AS "dist",
            ROW_NUMBER() OVER (PARTITION BY t."case_barcode"
                               ORDER BY SQRT(POWER(t."MT_CO1"-sc."AVG_CO1",2)
                                            +POWER(t."MT_CO2"-sc."AVG_CO2",2)
                                            +POWER(t."MT_CO3"-sc."AVG_CO3",2))) AS "rank1"
    FROM    test t
    CROSS JOIN stage_centroid sc
)

SELECT  "case_barcode",
        "candidate_stage" AS "predicted_clinical_stage"
FROM    distance_calc
WHERE   "rank1" = 1
ORDER BY "case_barcode";