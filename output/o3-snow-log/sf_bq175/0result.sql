/* -------------------------------------------------------------
   Top-11 cytobands on chromosome 1 (TCGA-KIRC / TCGA-KICH)
   for each CNV class – Amplification, Gain, Het Del.
---------------------------------------------------------------- */
WITH counts AS (   -- 1) event counts per cytoband & CNV category
    SELECT
        c."cytoband_name",
        CASE
            WHEN g."max_copy_number" >= 4 THEN 'Amplification'
            WHEN g."max_copy_number"  = 3 THEN 'Gain'
            WHEN g."max_copy_number"  = 1 THEN 'HetDel'
        END                                   AS "cnv_class",
        COUNT(*)                              AS "event_count"
    FROM  "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_GENE_LEVEL_HG38_GDC_R36" g
    JOIN  "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38"               c
      ON  g."chromosome" = c."chromosome"                       -- chr1 vs chr1
     AND LEAST(g."end_pos",   c."hg38_stop")                    -- physical overlap
       > GREATEST(g."start_pos", c."hg38_start")
    WHERE g."project_short_name" IN ('TCGA-KIRC','TCGA-KICH')   -- kidney projects present
      AND g."chromosome"         = 'chr1'                       -- chromosome-1 only
      AND g."max_copy_number" IN (1,3,4,5,6,7,8,9,10)           -- ignore diploid / null
    GROUP BY
        c."cytoband_name",
        CASE
            WHEN g."max_copy_number" >= 4 THEN 'Amplification'
            WHEN g."max_copy_number"  = 3 THEN 'Gain'
            WHEN g."max_copy_number"  = 1 THEN 'HetDel'
        END
    HAVING "cnv_class" IS NOT NULL
),
ranked AS (  -- 2) rank cytobands by frequency within each CNV class
    SELECT
        "cytoband_name",
        "cnv_class",
        "event_count",
        RANK() OVER (PARTITION BY "cnv_class"
                     ORDER BY "event_count" DESC NULLS LAST) AS "freq_rank"
    FROM counts
)
-- 3) keep only the top-11 cytobands for every CNV category
SELECT
    "cytoband_name",
    "cnv_class",
    "event_count",
    "freq_rank"
FROM   ranked
WHERE  "freq_rank" <= 11
ORDER  BY "cnv_class", "freq_rank", "cytoband_name";