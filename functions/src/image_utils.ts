import * as admin from "firebase-admin";
import sharp from "sharp";

/**
 * Determines if an image URL should be optimized
 * @param {string} imageUrl The image URL to check
 * @return {boolean} true if the image should be optimized
 */
export function shouldOptimizeImage(imageUrl: string): boolean {
  // Check if it's a Firebase Storage URL and contains PNG or JPG
  const isFirebaseStorage = imageUrl.includes("firebasestorage.googleapis.com") ||
                           imageUrl.includes("storage.googleapis.com");

  if (!isFirebaseStorage) {
    return false; // Don't process external images
  }

  // Check file extension (case insensitive)
  const lowerUrl = imageUrl.toLowerCase();
  return lowerUrl.includes(".png") ||
         lowerUrl.includes(".jpg") ||
         lowerUrl.includes(".jpeg");
}

/**
 * Converts a PNG/JPG image to WebP format
 * @param {string} originalImageUrl Firebase Storage URL of original image
 * @return {Promise<string>} Firebase Storage URL of the converted WebP image
 */
export async function convertImageToWebP(
  originalImageUrl: string
): Promise<string> {
  const bucket = admin.storage().bucket();

  try {
    // Extract the file path from the Firebase Storage URL
    const urlParts = originalImageUrl.split("/");
    const fileToken = urlParts[urlParts.length - 1];
    const [fileName] = fileToken.split("?");
    const decodedFileName = decodeURIComponent(fileName);

    console.log("📁 Processing file:", decodedFileName);

    // Download the original image
    const originalFile = bucket.file(decodedFileName);
    const [originalImageBuffer] = await originalFile.download();

    console.log("📥 Downloaded image, size:", originalImageBuffer.length,
      "bytes");

    // Convert to WebP using Sharp
    const webpBuffer = await sharp(originalImageBuffer)
      .webp({
        quality: 85, // High quality but still optimized
        effort: 4, // Good balance between size and processing time
      })
      .toBuffer();

    console.log("🔄 Converted to WebP, new size:", webpBuffer.length,
      "bytes");
    const reductionPercent = Math.round(
      (1 - webpBuffer.length / originalImageBuffer.length) * 100
    );
    console.log("💾 Size reduction:", reductionPercent + "%");

    // Create new filename with .webp extension
    const webpFileName = decodedFileName.replace(/\.(png|jpg|jpeg)$/i,
      ".webp");

    // Upload the WebP image
    const webpFile = bucket.file(webpFileName);
    await webpFile.save(webpBuffer, {
      metadata: {
        contentType: "image/webp",
        cacheControl: "public, max-age=31536000", // Cache for 1 year
      },
    });

    // Make the WebP image publicly accessible
    await webpFile.makePublic();

    // Get the public URL for the WebP image
    const webpUrl = `https://storage.googleapis.com/${bucket.name}/` +
      `${encodeURIComponent(webpFileName)}`;

    console.log("🌐 WebP image uploaded:", webpUrl);

    // Delete the original image to save storage space
    try {
      await originalFile.delete();
      console.log("🗑️  Original image deleted:", decodedFileName);
    } catch (deleteError) {
      console.error("⚠️  Could not delete original image:", deleteError);
      // Don't fail the entire process if deletion fails
    }

    return webpUrl;
  } catch (error) {
    console.error("❌ Error in convertImageToWebP:", error);
    throw new Error(`Image conversion failed: ${error}`);
  }
}
