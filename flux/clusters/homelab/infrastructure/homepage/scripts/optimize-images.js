const sharp = require('sharp');
const path = require('path');
const fs = require('fs');

async function optimizeImages() {
  console.log('🖼️  Starting image optimization...');
  
  const assetsDir = path.join(__dirname, '../frontend/public/assets');
  const euImagePath = path.join(assetsDir, 'eu.png');
  
  if (!fs.existsSync(euImagePath)) {
    console.log('❌ eu.png not found in assets directory');
    return;
  }
  
  // Get original file size
  const originalStats = fs.statSync(euImagePath);
  const originalSizeKB = (originalStats.size / 1024).toFixed(2);
  console.log(`📊 Original eu.png size: ${originalSizeKB} KB`);
  
  try {
    // Create optimized version with multiple formats
    const optimizedPath = path.join(assetsDir, 'eu-optimized.png');
    const webpPath = path.join(assetsDir, 'eu.webp');
    
    // Optimize PNG with sharp
    await sharp(euImagePath)
      .resize(400, 400, { // Resize to reasonable dimensions
        fit: 'cover',
        position: 'center'
      })
      .png({ 
        quality: 80, // Good quality with compression
        compressionLevel: 9 // Maximum compression
      })
      .toFile(optimizedPath);
    
    // Create WebP version (better compression)
    await sharp(euImagePath)
      .resize(400, 400, {
        fit: 'cover',
        position: 'center'
      })
      .webp({ 
        quality: 80,
        effort: 6 // Maximum compression effort
      })
      .toFile(webpPath);
    
    // Get optimized file sizes
    const optimizedStats = fs.statSync(optimizedPath);
    const webpStats = fs.statSync(webpPath);
    const optimizedSizeKB = (optimizedStats.size / 1024).toFixed(2);
    const webpSizeKB = (webpStats.size / 1024).toFixed(2);
    
    console.log(`✅ Optimized PNG size: ${optimizedSizeKB} KB (${((1 - optimizedStats.size / originalStats.size) * 100).toFixed(1)}% reduction)`);
    console.log(`✅ WebP size: ${webpSizeKB} KB (${((1 - webpStats.size / originalStats.size) * 100).toFixed(1)}% reduction)`);
    
    // Backup original and replace with optimized
    const backupPath = path.join(assetsDir, 'eu-original.png');
    fs.renameSync(euImagePath, backupPath);
    fs.renameSync(optimizedPath, euImagePath);
    
    console.log(`💾 Original backed up as eu-original.png`);
    console.log(`🚀 Image optimization complete!`);
    console.log(`💡 Consider using WebP format for even better performance`);
    
  } catch (error) {
    console.error('❌ Error optimizing image:', error);
  }
}

optimizeImages();
