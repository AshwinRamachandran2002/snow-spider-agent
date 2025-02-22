-- Task: Retrieve all SM images marked as 'VOLUME' from the DICOM_ALL table, including relevant metadata such as digital_slide_id, case_id, physical_slide_id, patient_id, width, height, collection_id, crdc_instance_uuid, gcs_url, pixel_spacing, and the compression type (jpeg, jpeg2000, or other) based on the TransferSyntaxUID.
SELECT
  "SeriesInstanceUID" AS "digital_slide_id",
  "StudyInstanceUID" AS "case_id",
  "ContainerIdentifier" AS "physical_slide_id",
  "PatientID" AS "patient_id",
  "TotalPixelMatrixColumns" AS "width",
  "TotalPixelMatrixRows" AS "height",
  "collection_id",
  "crdc_instance_uuid",
  "gcs_url",
  CAST(
    "SharedFunctionalGroupsSequence"[0]."PixelMeasuresSequence"[0]."PixelSpacing"[0] AS FLOAT
  ) AS "pixel_spacing",
  CASE "TransferSyntaxUID"
      WHEN '1.2.840.10008.1.2.4.50' THEN 'jpeg'
      WHEN '1.2.840.10008.1.2.4.91' THEN 'jpeg2000'
      ELSE 'other'
  END AS "compression"
FROM
  IDC.IDC_V17.DICOM_ALL
WHERE
  "Modality" = 'SM'
  AND "ImageType"[2] = 'VOLUME';