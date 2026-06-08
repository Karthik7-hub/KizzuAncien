require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const compression = require('compression');
const morgan = require('morgan');
const mongoose = require('mongoose');

const authRoutes = require('./routes/authRoutes');
const userRoutes = require('./routes/userRoutes');
const friendRoutes = require('./routes/friendRoutes');
const challengeRoutes = require('./routes/challengeRoutes');
const truthDareRoutes = require('./routes/truthDareRoutes');
const notificationRoutes = require('./routes/notificationRoutes');
const { errorHandler } = require('./middleware/errorMiddleware');

const app = express();
const isProduction = process.env.NODE_ENV === 'production';

// Trust proxy for Vercel and other reverse proxies
app.set('trust proxy', 1);

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
  message: 'Too many requests from this IP, please try again after 15 minutes'
});

// Middleware
app.use(helmet({
  contentSecurityPolicy: isProduction ? undefined : false
}));
app.use(limiter);
app.use(compression());
app.use(cors({
  origin: true, // Native apps don't send Origin headers usually, keep true or specific domain
  credentials: true
}));
app.use(express.json());

if (!isProduction) {
  app.use(morgan('dev'));
}

// Routes
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/friends', friendRoutes);
app.use('/api/challenges', challengeRoutes);
app.use('/api/truth-dare', truthDareRoutes);
app.use('/api/notifications', notificationRoutes);

app.get('/', (req, res) => res.json({ status: 'KizzuAncien API' }));
app.get('/health', (req, res) => res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() }));

app.use(errorHandler);

// Database connection for Serverless
const connectDB = async () => {
  if (mongoose.connection.readyState >= 1) return;
  try {
    await mongoose.connect(process.env.MONGO_URI);
    console.log('✅ MongoDB Connected');
  } catch (err) {
    console.error('❌ MongoDB Connection Error:', err.message);
  }
};

// Start server for local dev or handle serverless
if (process.env.NODE_ENV !== 'production') {
  const PORT = process.env.PORT || 5000;
  connectDB().then(() => {
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`🚀 Local Server running at: http://localhost:${PORT}`);
    });
  });
} else {
  // On Vercel, we just need to ensure the DB connects when the lambda starts
  connectDB();
}

module.exports = app;
