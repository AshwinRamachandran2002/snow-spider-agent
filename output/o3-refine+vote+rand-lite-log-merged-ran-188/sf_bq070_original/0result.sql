SELECT
    "UID"                                   AS "digital_slide_id",
    "StudyInstanceUID"                      AS "case_id",
    "ContainerIdentifier"                   AS "physical_slide_id",
    "PatientID"                             AS "patient_id",
    "collection_id"                         AS "collection_id",
    "SOPInstanceUID"                        AS "instance_id",
    "gcs_url"                               AS "gcs_url",
    "Columns"                               AS "width",
    "Rows"                                  AS "height",
    CAST("PixelSpacing" AS STRING)          AS "pixel_spacing",
    /* ----------------------------------------------------------------------
       compression type
    ---------------------------------------------------------------------- */
    CASE
        WHEN "TransferSyntaxUID" IN
             ('1.2.840.10008.1.2.4.50',  -- JPEG Baseline
              '1.2.840.10008.1.2.4.51',  -- JPEG Extended
              '1.2.840.10008.1.2.4.57',  -- JPEG Lossless (NH)
              '1.2.840.10008.1.2.4.70',  -- JPEG Lossless (H)
              '1.2.840.10008.1.2.4.80',  -- JPEG‑LS Lossless
              '1.2.840.10008.1.2.4.81')  -- JPEG‑LS Near‑lossless
          THEN 'jpeg'
        WHEN "TransferSyntaxUID" IN
             ('1.2.840.10008.1.2.4.90',  -- JPEG2000 Lossless
              '1.2.840.10008.1.2.4.91')  -- JPEG2000
          THEN 'jpeg2000'
        ELSE 'other'
    END                                     AS "compression_type",
    /* ----------------------------------------------------------------------
       tissue type based on SNOMED codes: 17621005 = normal tissue,
                                          86049000 = tumor tissue
    ---------------------------------------------------------------------- */
    CASE
        WHEN (CAST("SpecimenDescriptionSequence" AS STRING) ILIKE '%"CodeValue":"17621005"%' OR
              CAST("AnatomicRegionSequence"     AS STRING) ILIKE '%"CodeValue":"17621005"%')
             THEN 'normal'
        WHEN (CAST("SpecimenDescriptionSequence" AS STRING) ILIKE '%"CodeValue":"86049000"%' OR
              CAST("AnatomicRegionSequence"     AS STRING) ILIKE '%"CodeValue":"86049000"%')
             THEN 'tumor'
    END                                     AS "tissue_type",
    /* ----------------------------------------------------------------------
       cancer subtype from collection
    ---------------------------------------------------------------------- */
    CASE
        WHEN "collection_id" = 'tcga_luad' THEN 'luad'
        WHEN "collection_id" = 'tcga_lusc' THEN 'lscc'
    END                                     AS "cancer_subtype"
FROM
    "IDC"."IDC_V17"."DICOM_ALL"
WHERE
      /* TCGA lung collections only */
      "collection_id" IN ('tcga_luad', 'tcga_lusc')
  /* Slide‑microscopy images marked as VOLUME */
  AND "Modality" = 'SM'
  AND "VolumetricProperties" = 'VOLUME'
  /* Keep only JPEG / JPEG2000 compressed images */
  AND CASE
          WHEN "TransferSyntaxUID" IN
               ('1.2.840.10008.1.2.4.50','1.2.840.10008.1.2.4.51',
                '1.2.840.10008.1.2.4.57','1.2.840.10008.1.2.4.70',
                '1.2.840.10008.1.2.4.80','1.2.840.10008.1.2.4.81')
               THEN 'jpeg'
          WHEN "TransferSyntaxUID" IN
               ('1.2.840.10008.1.2.4.90','1.2.840.10008.1.2.4.91')
               THEN 'jpeg2000'
          ELSE 'other'
      END <> 'other'
  /* Specimen embedded in Tissue freezing medium */
  AND CAST("SpecimenDescriptionSequence" AS STRING) ILIKE '%Tissue freezing medium%'
  /* Require explicit normal or tumor tissue code */
  AND (
        (CAST("SpecimenDescriptionSequence" AS STRING) ILIKE '%"CodeValue":"17621005"%' OR
         CAST("AnatomicRegionSequence"     AS STRING) ILIKE '%"CodeValue":"17621005"%')
     OR (CAST("SpecimenDescriptionSequence" AS STRING) ILIKE '%"CodeValue":"86049000"%' OR
         CAST("AnatomicRegionSequence"     AS STRING) ILIKE '%"CodeValue":"86049000"%')
      )
ORDER BY
    "instance_id" ASC;