/*-------------------------------------------------------------
  Copy-number subtype frequencies across cytobands in TCGA-KIRC
--------------------------------------------------------------*/
WITH kirc_segments AS (      -- 1)  only TCGA-KIRC allelic CNV segments
    SELECT
        "project_short_name",
        "chromosome",
        "start_pos",
        "end_pos",
        "copy_number"
    FROM "TCGA_MITELMAN"."TCGA_VERSIONED"."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE "project_short_name" = 'TCGA-KIRC'
),

seg_band_max AS (            -- 2)  overlap with cytobands and keep the
                             --     maximum copy-number per case & band
    SELECT
        s."project_short_name"         AS "case_id",
        b."chromosome",
        b."cytoband_name",
        MAX(s."copy_number")           AS "max_copy_number"
    FROM kirc_segments               s
    JOIN "TCGA_MITELMAN"."PROD"."CYTOBANDS_HG38"  b
      ON s."chromosome" = b."chromosome"
     AND LEAST(s."end_pos" , b."hg38_stop" ) 
       > GREATEST(s."start_pos", b."hg38_start")
    GROUP BY
        s."project_short_name",
        b."chromosome",
        b."cytoband_name"
),

classified AS (               -- 3)  assign CNV sub-types
    SELECT
        "case_id",
        "chromosome",
        "cytoband_name",
        CASE
             WHEN "max_copy_number" > 3 THEN 'Amplification'
             WHEN "max_copy_number" = 3 THEN 'Gain'
             WHEN "max_copy_number" = 2 THEN 'Normal'
             WHEN "max_copy_number" = 1 THEN 'Heterozygous Deletion'
             WHEN "max_copy_number" = 0 THEN 'Homozygous Deletion'
             ELSE 'Other'
        END                                   AS "cnv_class"
    FROM seg_band_max
),

total_cases AS (              -- 4)  denominator for frequency (%)
    SELECT COUNT(DISTINCT "case_id") AS "n_cases"
    FROM classified
),

per_band_freq AS (            -- 5)  #cases per cytoband & CNV class
    SELECT
        "chromosome",
        "cytoband_name",
        "cnv_class",
        COUNT(DISTINCT "case_id")     AS "num_cases"
    FROM classified
    GROUP BY
        "chromosome",
        "cytoband_name",
        "cnv_class"
)

-- 6)  final percentages, sorted by chromosome & cytoband
SELECT
    f."chromosome",
    f."cytoband_name",
    f."cnv_class",
    ROUND(100.0 * f."num_cases" / t."n_cases", 2) AS "frequency_pct"
FROM per_band_freq  f
CROSS JOIN total_cases t
ORDER BY
    f."chromosome",
    f."cytoband_name",
    f."cnv_class";