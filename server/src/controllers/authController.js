const User = require('../models/User');
const jwt = require('jsonwebtoken');
const admin = require('../config/firebase');

const generateTokens = (id) => {
  // Access token valid for 1 hour, Refresh token valid for 30 days
  const accessToken = jwt.sign({ id }, process.env.JWT_ACCESS_SECRET, { expiresIn: '1h' });
  const refreshToken = jwt.sign({ id }, process.env.JWT_REFRESH_SECRET, { expiresIn: '30d' });
  return { accessToken, refreshToken };
};

exports.register = async (req, res, next) => {
  try {
    const { name, email, password, username, gender } = req.body;
    const userExists = await User.findOne({ $or: [{ email }, { username }] });
    if (userExists) {
      return res.status(400).json({ message: 'User already exists' });
    }

    const avatarType = gender === 'male' ? 'male_default' : 'female_default';

    const user = await User.create({
      name,
      email,
      password,
      username,
      gender,
      avatarType
    });
    const { accessToken, refreshToken } = generateTokens(user._id);
    res.status(201).json({ user, accessToken, refreshToken });
  } catch (error) {
    next(error);
  }
};

exports.login = async (req, res, next) => {
  try {
    const { email, password } = req.body;
    const user = await User.findOne({ email });
    if (user && (await user.comparePassword(password))) {
      const { accessToken, refreshToken } = generateTokens(user._id);
      res.json({ user, accessToken, refreshToken });
    } else {
      res.status(401).json({
        message: user ? 'Incorrect password' : 'User not found'
      });
    }
  } catch (error) {
    next(error);
  }
};

exports.googleLogin = async (req, res, next) => {
  try {
    const { googleId, email, name, gender, username, idToken } = req.body;

    if (!idToken) {
      return res.status(400).json({ message: 'Google ID Token is required' });
    }

    // Verify Firebase ID Token
    let decodedToken;
    try {
      if (!admin.apps.length) {
        throw new Error('Firebase Admin not initialized');
      }
      decodedToken = await admin.auth().verifyIdToken(idToken);
      if (decodedToken.email !== email) {
        return res.status(401).json({ message: `Email mismatch: Token is for ${decodedToken.email}, but you provided ${email}` });
      }
    } catch (err) {
      console.error('Google Login Token Error:', err.message);
      return res.status(401).json({ message: `Token verification failed: ${err.message}` });
    }

    let user = await User.findOne({ email });

    if (!user) {
      // If user doesn't exist, we expect gender and username to be provided from the frontend
      if (!gender || !username) {
        return res.status(200).json({
          exists: false,
          message: 'User does not exist. Please provide gender and username to complete registration.'
        });
      }

      const avatarType = gender === 'male' ? 'male_default' : 'female_default';

      user = await User.create({
        name,
        email,
        googleId,
        username,
        gender,
        avatarType
      });
    } else {
      // User exists, update googleId if not present
      if (!user.googleId) {
        user.googleId = googleId;
        await user.save();
      }
    }

    const { accessToken, refreshToken } = generateTokens(user._id);
    res.json({ user, accessToken, refreshToken, exists: true });
  } catch (error) {
    next(error);
  }
};

exports.checkEmail = async (req, res, next) => {
  try {
    const user = await User.findOne({ email: req.params.email });
    res.json({ exists: !!user });
  } catch (error) {
    next(error);
  }
};

exports.refreshToken = async (req, res, next) => {
  try {
    const { token } = req.body;
    if (!token) return res.status(401).json({ message: 'Refresh Token is required' });

    try {
      const decoded = jwt.verify(token, process.env.JWT_REFRESH_SECRET);

      const user = await User.findById(decoded.id);
      if (!user) {
        return res.status(401).json({ message: 'User no longer exists' });
      }

      const { accessToken, refreshToken } = generateTokens(user._id);
      res.json({ accessToken, refreshToken });
    } catch (err) {
      return res.status(401).json({ message: 'Refresh token is invalid or expired' });
    }
  } catch (error) {
    next(error);
  }
};
