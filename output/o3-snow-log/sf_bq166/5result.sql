/*---------------------------------------------------------------------------
  Cytoband-level CNV subtype frequencies for TCGA-KIRC
---------------------------------------------------------------------------*/
WITH total_cases AS (   -- how many distinct KIRC “cases” exist in the segment table
    SELECT COUNT( DISTINCT
                  CONCAT_WS('::',
                            "project_short_name",
                            "chromosome",
                            "start_pos",
                            "end_pos") )  AS "n_cases"
    FROM   TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"
    WHERE  "project_short_name" = 'TCGA-KIRC'
),  -------------------------------------------------------------------------
max_cnv_per_band AS (   -- maximum copy-number each cytoband attains in KIRC
    SELECT
        s."project_short_name",
        c."chromosome",
        c."cytoband_name",
        MAX( s."copy_number" ) AS "max_copy_number"
    FROM   TCGA_MITELMAN.TCGA_VERSIONED."COPY_NUMBER_SEGMENT_ALLELIC_HG38_GDC_R23"  s
    JOIN   TCGA_MITELMAN.PROD."CYTOBANDS_HG38"                                      c
           ON  s."chromosome" = c."chromosome"          -- same chromosome
           AND s."start_pos"  <= c."hg38_stop"          -- interval overlap
           AND s."end_pos"    >= c."hg38_start"
    WHERE  s."project_short_name" = 'TCGA-KIRC'
    GROUP BY
        s."project_short_name",
        c."chromosome",
        c."cytoband_name"
),  -------------------------------------------------------------------------
classified AS (         -- translate the maxima into the five CNV classes
    SELECT
        "project_short_name",
        "chromosome",
        "cytoband_name",
        CASE
            WHEN "max_copy_number" > 3 THEN 'Amplification'
            WHEN "max_copy_number" = 3 THEN 'Gain'
            WHEN "max_copy_number" = 2 THEN 'Normal'
            WHEN "max_copy_number" = 1 THEN 'HetDel'
            WHEN "max_copy_number" = 0 THEN 'HomDel'
            ELSE                        'Other'
        END AS "cnv_class"
    FROM   max_cnv_per_band
),  -------------------------------------------------------------------------
band_class_counts AS (  -- raw counts of classes per cytoband
    SELECT
        "chromosome",
        "cytoband_name",
        "cnv_class",
        COUNT(*) AS "class_count"
    FROM   classified
    GROUP BY
        "chromosome",
        "cytoband_name",
        "cnv_class"
)  ---------------------------------------------------------------------------
SELECT
    b."chromosome",
    b."cytoband_name",
    b."cnv_class",
    ROUND( 100.0 * b."class_count" / t."n_cases" , 2)  AS "percentage_of_cases"
FROM   band_class_counts b
CROSS  JOIN total_cases t
ORDER  BY
    LPAD( REGEXP_REPLACE(b."chromosome", 'chr', ''), 2 , '0' ),   -- chr1 < chr2 < chr10 …
    b."cytoband_name",
    b."cnv_class";