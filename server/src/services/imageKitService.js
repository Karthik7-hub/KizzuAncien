const ImageKit = require("imagekit");

const imageKit = new ImageKit({
  publicKey: process.env.IMAGEKIT_PUBLIC_KEY,
  privateKey: process.env.IMAGEKIT_PRIVATE_KEY,
  urlEndpoint: process.env.IMAGEKIT_URL_ENDPOINT,
});

exports.uploadImage = async (fileBuffer, fileName) => {
  try {
    const result = await imageKit.upload({
      file: fileBuffer,
      fileName: fileName,
      folder: '/kizzu-ancien'
    });
    return result;
  } catch (error) {
    throw new Error('ImageKit upload failed: ' + error.message);
  }
};

exports.deleteImage = async (fileId) => {
  try {
    await imageKit.deleteFile(fileId);
  } catch (error) {
    console.error('ImageKit delete failed:', error.message);
  }
};
