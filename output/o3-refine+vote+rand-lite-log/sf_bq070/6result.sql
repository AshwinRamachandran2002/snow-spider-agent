SELECT
    "SeriesInstanceUID"                            AS "digital_slide_id",
    "StudyInstanceUID"                             AS "case_id",
    "ContainerIdentifier"                          AS "physical_slide_id",
    "PatientID"                                    AS "patient_id",
    "collection_id"                                AS "collection_id",
    "SOPInstanceUID"                               AS "instance_id",
    "gcs_url"                                      AS "gcs_url",
    "TotalPixelMatrixColumns"                      AS "width",
    "TotalPixelMatrixRows"                         AS "height",
    COALESCE(
        CAST("NominalScannedPixelSpacing" AS STRING),
        CAST("PixelSpacing"               AS STRING)
    )                                              AS "pixel_spacing",
    CASE
        WHEN "TransferSyntaxUID" IN (
             '1.2.840.10008.1.2.4.50',  -- JPEG Baseline
             '1.2.840.10008.1.2.4.51',  -- JPEG Extended
             '1.2.840.10008.1.2.4.57',  -- JPEG Lossless, non‑hierarchical
             '1.2.840.10008.1.2.4.70'   -- JPEG Lossless, non‑hierarchical, first‑order prediction
        ) THEN 'jpeg'
        WHEN "TransferSyntaxUID" IN (
             '1.2.840.10008.1.2.4.90',  -- JPEG2000 Lossless
             '1.2.840.10008.1.2.4.91'   -- JPEG2000
        ) THEN 'jpeg2000'
        ELSE 'other'
    END                                             AS "compression_type",
    CASE
        WHEN LOWER(CAST("SpecimenDescriptionSequence" AS STRING)) LIKE '%17621005%'
          OR LOWER(CAST("AnatomicRegionSequence"      AS STRING)) LIKE '%17621005%'
             THEN 'normal'
        ELSE 'tumor'
    END                                             AS "tissue_type",
    CASE
        WHEN "collection_id" = 'tcga_luad' THEN 'luad'
        ELSE 'lscc'
    END                                             AS "cancer_subtype"
FROM IDC.IDC_V17.DICOM_ALL
WHERE
      "Modality"              = 'SM'
  AND "VolumetricProperties"  = 'VOLUME'
  AND "collection_id" IN ('tcga_luad', 'tcga_lusc')
  AND (
        CASE
            WHEN "TransferSyntaxUID" IN (
                 '1.2.840.10008.1.2.4.50',
                 '1.2.840.10008.1.2.4.51',
                 '1.2.840.10008.1.2.4.57',
                 '1.2.840.10008.1.2.4.70'
            ) THEN 'jpeg'
            WHEN "TransferSyntaxUID" IN (
                 '1.2.840.10008.1.2.4.90',
                 '1.2.840.10008.1.2.4.91'
            ) THEN 'jpeg2000'
            ELSE 'other'
        END
      ) IN ('jpeg', 'jpeg2000')                     -- exclude “other” compression
  AND LOWER(CAST("SpecimenDescriptionSequence" AS STRING)) LIKE '%tissue freezing medium%'
  AND (
         LOWER(CAST("SpecimenDescriptionSequence" AS STRING)) LIKE '%17621005%'
      OR LOWER(CAST("SpecimenDescriptionSequence" AS STRING)) LIKE '%86049000%'
      OR LOWER(CAST("AnatomicRegionSequence"      AS STRING)) LIKE '%17621005%'
      OR LOWER(CAST("AnatomicRegionSequence"      AS STRING)) LIKE '%86049000%'
  )
ORDER BY "instance_id" ASC;